import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/models/gun.dart';
import 'package:gungeon_mate/models/player.dart';
import 'package:gungeon_mate/models/synergy.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/screens/item_detail_screen.dart';
import 'package:gungeon_mate/services/app_theme.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/widgets/item_detail/gun_synergies_tab.dart';

/// Lich's Eye Bullets synergy display — the VisualPrefs toggle, the
/// simulated LEB view (default), and the actual COMPLETE/PARTIAL/LOCKED
/// grouping shown when the toggle is off. Also pins the data invariant
/// that every synergy piece resolves against the gun/item catalogs.
///
/// Data loads in setUpAll (real async zone): inside testWidgets'
/// FakeAsync zone the compute() isolate futures never resolve.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RunProvider p;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    p = RunProvider();
    await p.loadData();
  });

  setUp(() {
    // Clean inventory + default prefs before every test — addGun/addItem
    // and the LEB setter mutate shared state.
    p.endRun();
    VisualPrefs.notifier.value = const VisualPrefs();
  });

  Widget wrap(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: p),
      ChangeNotifierProvider(create: (_) => MpSession.placeholder()),
    ],
    child: MaterialApp(home: child),
  );

  /// A gun + simple 2-piece synergy (no anyOf) whose partner resolves
  /// in the catalog — deterministic driver for COMPLETE/PARTIAL tests.
  ({Gun gun, Synergy synergy, String partner}) findPair() {
    for (final gun in p.allGuns) {
      final lower = gun.name.toLowerCase();
      for (final s in p.getSynergiesFor(gun.name)) {
        if (s.items.length != 2 || s.anyOf.isNotEmpty) continue;
        // The LEB ghost list skips hard-excluded (dual-wield etc.) and
        // 3+-piece synergies — pick a pair that actually renders there.
        if (isLebExcludedSynergy(s) || lebNeedsRealPieces(s)) continue;
        if (!s.items.any((i) => i.toLowerCase() == lower)) continue;
        final partner = s.items.firstWhere(
          (i) => i.toLowerCase() != lower,
        );
        final r = p.entityByName(partner);
        if (r.gun != null || r.item != null) {
          return (gun: gun, synergy: s, partner: partner);
        }
      }
    }
    throw StateError('catalog has no 2-piece gun synergy');
  }

  void ownPartner(String partner) {
    final r = p.entityByName(partner);
    if (r.item != null) {
      p.addItem(r.item!, slot: PlayerSlot.main);
    } else {
      p.addGun(r.gun!, slot: PlayerSlot.main);
    }
  }

  // NB: the detail pager adds a horizontal PageView Scrollable, so
  // scrollUntilVisible calls must pass `scrollable:
  // find.byType(Scrollable).first` (the outer vertical one) explicitly.
  /// Gun detail bottom tabs are closed by default — expand SYN
  /// before asserting on synergy content.
  Future<void> openSynTab(WidgetTester t) async {
    await t.scrollUntilVisible(
      find.text('SYN'),
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 30,
    );
    await t.pump();
    await t.tap(find.text('SYN'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
  }

  Future<void> scrollToSynergySection(WidgetTester t) async {
    await t.scrollUntilVisible(
      find.textContaining('LICH'),
      400,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 40,
    );
    await t.pump();
  }

  group('VisualPrefs.showLichEyeBulletsSynergies', () {
    test('defaults to true', () {
      expect(const VisualPrefs().showLichEyeBulletsSynergies, isTrue);
    });

    test('setter updates the notifier', () async {
      await VisualPrefs.setShowLichEyeBulletsSynergies(false);
      expect(
        VisualPrefs.notifier.value.showLichEyeBulletsSynergies,
        isFalse,
      );
    });

    test('persists false across a prefs reload', () async {
      await VisualPrefs.setShowLichEyeBulletsSynergies(false);
      await VisualPrefs.init();
      expect(
        VisualPrefs.notifier.value.showLichEyeBulletsSynergies,
        isFalse,
      );
    });

    test('missing key loads as true (default-on for existing users)', () async {
      SharedPreferences.setMockInitialValues({});
      await VisualPrefs.init();
      expect(
        VisualPrefs.notifier.value.showLichEyeBulletsSynergies,
        isTrue,
      );
    });
  });

  group('gun detail — LEB simulated view (default)', () {
    testWidgets('empty inventory still lists every synergy as LEB', (
      t,
    ) async {
      final pair = findPair();
      await t.pumpWidget(wrap(ItemDetailScreen(gun: pair.gun)));
      await t.pump();
      await openSynTab(t);
      await scrollToSynergySection(t);

      expect(t.takeException(), isNull);
      expect(find.text("LICH'S EYE BULLETS"), findsOneWidget);
      expect(find.text(pair.synergy.name), findsOneWidget);
      expect(find.text('LEB'), findsWidgets);
      // Simulated mode never shows the actual-state group headers.
      expect(find.text('LOCKED'), findsNothing);
      expect(find.text('COMPLETE'), findsNothing);
      expect(find.text('PARTIAL'), findsNothing);
    });

    testWidgets('flipping the toggle live swaps to the actual view', (
      t,
    ) async {
      final pair = findPair();
      await t.pumpWidget(wrap(ItemDetailScreen(gun: pair.gun)));
      await t.pump();
      await openSynTab(t);
      await scrollToSynergySection(t);
      expect(find.text("LICH'S EYE BULLETS"), findsOneWidget);

      await VisualPrefs.setShowLichEyeBulletsSynergies(false);
      await t.pump();
      // ValueListenableBuilder must rebuild without a re-pumpWidget.
      expect(find.text("LICH'S EYE BULLETS"), findsNothing);
      // Flat grouped list — LOCKED header sits below the fold.
      await t.scrollUntilVisible(
        find.text('LOCKED'),
        400,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 40,
      );
      await t.pump();
      expect(find.text('LOCKED'), findsOneWidget);
      expect(find.text(pair.synergy.name), findsOneWidget);
    });
  });

  group('gun detail — actual view (LEB toggle off)', () {
    testWidgets('empty inventory groups every synergy as LOCKED', (t) async {
      await VisualPrefs.setShowLichEyeBulletsSynergies(false);
      final pair = findPair();
      await t.pumpWidget(wrap(ItemDetailScreen(gun: pair.gun)));
      await t.pump();
      await openSynTab(t);
      await t.scrollUntilVisible(
        find.text('LOCKED'),
        400,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 40,
      );
      await t.pump();

      expect(t.takeException(), isNull);
      expect(find.text('LOCKED'), findsOneWidget);
      expect(find.text('NONE'), findsWidgets);
      expect(find.text(pair.synergy.name), findsOneWidget);
      expect(find.text("LICH'S EYE BULLETS"), findsNothing);
    });

    testWidgets('owning one partner piece groups as PARTIAL', (t) async {
      await VisualPrefs.setShowLichEyeBulletsSynergies(false);
      final pair = findPair();
      ownPartner(pair.partner);
      // Flush the 400ms _scheduleSave debounce timer.
      await t.pump(const Duration(milliseconds: 500));
      await t.pumpWidget(wrap(ItemDetailScreen(gun: pair.gun)));
      await t.pump();
      await openSynTab(t);
      await t.scrollUntilVisible(
        find.text('PARTIAL'),
        400,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 40,
      );
      await t.pump();

      expect(t.takeException(), isNull);
      expect(find.text('PARTIAL'), findsOneWidget);
      expect(find.text(pair.synergy.name), findsOneWidget);
    });

    testWidgets('owning gun + partner groups as COMPLETE', (t) async {
      await VisualPrefs.setShowLichEyeBulletsSynergies(false);
      final pair = findPair();
      p.addGun(pair.gun, slot: PlayerSlot.main);
      ownPartner(pair.partner);
      // Flush the 400ms _scheduleSave debounce timer.
      await t.pump(const Duration(milliseconds: 500));
      await t.pumpWidget(wrap(ItemDetailScreen(gun: pair.gun)));
      await t.pump();
      await openSynTab(t);
      await t.scrollUntilVisible(
        find.text('COMPLETE'),
        400,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 40,
      );
      await t.pump();

      expect(t.takeException(), isNull);
      expect(find.text('COMPLETE'), findsOneWidget);
      expect(find.text(pair.synergy.name), findsOneWidget);
    });
  });

  group('gun detail — swipeable pager', () {
    testWidgets('co-op run offers ALL/P1/P2/LEB pages', (t) async {
      // Empty co-op slot — P2 page should show the label-only empty note.
      p.applyPartnerSnapshot(
        characterName: '',
        gunNames: const [],
        itemNames: const [],
      );
      await t.pump(const Duration(milliseconds: 500));
      final pair = findPair();
      await t.pumpWidget(
        wrap(ItemDetailScreen(gun: pair.gun, lebView: true)),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      await openSynTab(t);
      await scrollToSynergySection(t);

      expect(t.takeException(), isNull);
      // Chips for every page are present.
      for (final label in ['ALL', 'P1', 'P2', 'LEB']) {
        expect(find.text(label), findsWidgets, reason: 'missing $label');
      }
      // LEB context lands on the simulated page.
      expect(find.text("LICH'S EYE BULLETS"), findsOneWidget);

      // Swipe back one page (LEB → P2) — empty player shows label only.
      await t.drag(find.byType(PageView), const Offset(400, 0));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('P2 has no items yet.'), findsOneWidget);
    });

    testWidgets('run-context detail (lebView false) hides the LEB page', (
      t,
    ) async {
      final pair = findPair();
      await t.pumpWidget(
        wrap(ItemDetailScreen(gun: pair.gun, lebView: false)),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      await openSynTab(t);
      await t.scrollUntilVisible(
        find.text('LOCKED'),
        400,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 40,
      );
      await t.pump();

      expect(t.takeException(), isNull);
      expect(find.text("LICH'S EYE BULLETS"), findsNothing);
      // Solo + no LEB → flat grouped list, no pager chips at all.
      expect(find.text('LEB'), findsNothing);
      expect(find.text('LOCKED'), findsOneWidget);
    });
  });

  group('item detail — grouped all-list', () {
    testWidgets('item lists every synergy grouped by state', (t) async {
      // Find an item + simple 2-piece synergy whose partner resolves.
      ({String item, String partner, String synName})? found;
      for (final item in p.allItems) {
        final lower = item.name.toLowerCase();
        for (final s in p.getSynergiesFor(item.name)) {
          if (s.items.length != 2 || s.anyOf.isNotEmpty) continue;
          if (!s.items.any((i) => i.toLowerCase() == lower)) continue;
          final partner = s.items.firstWhere(
            (i) => i.toLowerCase() != lower,
          );
          final r = p.entityByName(partner);
          if (r.gun != null || r.item != null) {
            found = (item: item.name, partner: partner, synName: s.name);
            break;
          }
        }
        if (found != null) break;
      }
      final f = found ?? (throw StateError('no item synergy pair'));
      ownPartner(f.partner);
      await t.pump(const Duration(milliseconds: 500));

      final item = p.allItems.firstWhere((i) => i.name == f.item);
      await t.pumpWidget(wrap(ItemDetailScreen(item: item)));
      await t.pump();
      await t.scrollUntilVisible(
        find.text('PARTIAL'),
        400,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 40,
      );
      await t.pump();

      expect(t.takeException(), isNull);
      expect(find.text('PARTIAL'), findsOneWidget);
      expect(find.text(f.synName), findsOneWidget);
      // Items never get the LEB simulated view.
      expect(find.text("LICH'S EYE BULLETS"), findsNothing);
    });
  });

  group('edge cases', () {
    testWidgets('gun with zero catalog synergies shows empty state', (
      t,
    ) async {
      final gun = p.allGuns.firstWhere(
        (g) => p.getSynergiesFor(g.name).isEmpty,
        orElse: () => throw StateError('every gun has a synergy'),
      );
      // Both modes must degrade to an honest empty state — the LEB
      // page keeps its header + note, the real view shows the generic
      // empty state.
      for (final leb in [true, false]) {
        await VisualPrefs.setShowLichEyeBulletsSynergies(leb);
        // Reset the tree — reusing the State would keep _detailTab open
        // and the second openSynTab tap would toggle it shut.
        await t.pumpWidget(const SizedBox());
        await t.pumpWidget(wrap(ItemDetailScreen(gun: gun)));
        await t.pump();
        await t.pump(const Duration(milliseconds: 100));
        await openSynTab(t);
        final expected = leb ? 'This gun has no synergies' : 'No synergies';
        await t.scrollUntilVisible(
          find.textContaining(expected),
          400,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 40,
        );
        await t.pump();
        expect(t.takeException(), isNull);
        expect(find.textContaining(expected), findsWidgets);
      }
    });

    testWidgets('item detail never shows the LEB simulated view', (t) async {
      final item = p.allItems.firstWhere(
        (i) =>
            i.name != "Lich's Eye Bullets" &&
            p.getSynergiesFor(i.name).isNotEmpty,
        orElse: () => throw StateError('no item with synergies'),
      );
      await t.pumpWidget(wrap(ItemDetailScreen(item: item)));
      await t.pump();

      expect(t.takeException(), isNull);
      expect(find.text("LICH'S EYE BULLETS"), findsNothing);
      // Items keep the classic SynergiesSection header.
      expect(find.text('SYNERGIES'), findsWidgets);
    });
  });

  group('data integrity', () {
    test('all-guns sweep: every gun partitions cleanly in every view', () {
      // For every gun × every inventory slice, COMPLETE + PARTIAL +
      // LOCKED must account for ALL of its synergies — no drops, no
      // double-counts. This is the bughunt net for the pager views.
      final slices = <String, List<String>>{
        'ALL': p.runState.allItemNames,
        'P1': p.runState.main.allItemNames,
        'P2': p.runState.coop?.allItemNames ?? const <String>[],
      };
      for (final g in p.allGuns) {
        final synergies = p.getSynergiesFor(g.name);
        final cur = g.name.toLowerCase();
        for (final slice in slices.entries) {
          final owned = slice.value;
          final ownedLower = owned.map((n) => n.toLowerCase()).toSet();
          var complete = 0, partial = 0, locked = 0;
          for (final s in synergies) {
            if (s.matchesItems(owned)) {
              complete++;
            } else {
              final hasPiece = [
                ...s.items,
                ...s.anyOf,
              ].any((i) {
                final pl = i.toLowerCase();
                return pl != cur && ownedLower.contains(pl);
              });
              if (hasPiece) {
                partial++;
              } else {
                locked++;
              }
            }
          }
          expect(
            complete + partial + locked,
            synergies.length,
            reason:
                '${g.name} [${slice.key}]: '
                '$complete+$partial+$locked != ${synergies.length}',
          );
        }
      }
    });

    test('every synergy piece resolves against the catalogs', () {
      final unresolved = <String>[];
      for (final s in p.allSynergies) {
        for (final piece in [...s.items, ...s.anyOf]) {
          final r = p.entityByName(piece);
          if (r.gun == null && r.item == null) {
            unresolved.add('${s.name} -> $piece');
          }
        }
      }
      expect(unresolved, isEmpty, reason: unresolved.join('\n'));
    });

    test('getSynergiesFor covers items- and anyOf-referenced guns', () {
      // Regression: the gun detail list is driven entirely by
      // getSynergiesFor — a gun referenced only via anyOf must still
      // appear.
      final anyOfGun = p.allSynergies
          .expand((s) => s.anyOf)
          .map((n) => n.toLowerCase())
          .toSet();
      final covered = p.allGuns
          .where((g) => anyOfGun.contains(g.name.toLowerCase()))
          .where((g) => p.getSynergiesFor(g.name).isNotEmpty)
          .length;
      final total = p.allGuns
          .where((g) => anyOfGun.contains(g.name.toLowerCase()))
          .length;
      expect(covered, total);
    });
  });
}
