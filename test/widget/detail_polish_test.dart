import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/screens/item_detail_screen.dart';
import 'package:gungeon_mate/screens/synergy_detail_screen.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/widgets/item_detail/entity_synergies_view.dart';
import 'package:gungeon_mate/widgets/scale_button.dart';

void main() {
  late RunProvider p;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    p = RunProvider();
    await p.loadData();
  });

  Widget wrap(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: p),
      ChangeNotifierProvider(create: (_) => MpSession(p)),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );

  /// Bounded-height wrapper for list fragments (EntitySynergiesView is
  /// designed for slivers — needs a scroll viewport in tests).
  Widget wrapScroll(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: p),
      ChangeNotifierProvider(create: (_) => MpSession(p)),
    ],
    child: MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );

  testWidgets('gun detail shows fire-mode chip and a single sell badge', (
    t,
  ) async {
    final gun = p.allGuns.firstWhere((g) => g.type.isNotEmpty);
    await t.pumpWidget(wrap(ItemDetailScreen(gun: gun)));
    await t.pump();
    expect(t.takeException(), isNull);
    // Fire-mode chip (U-048) — subtitle rendered in the badge row.
    expect(find.text(gun.type), findsWidgets);
    // U-047: exactly one sell affordance (badge), no duplicate chip.
    expect(find.byIcon(Icons.sell_outlined), findsOneWidget);
    expect(find.byIcon(Icons.payments_outlined), findsNothing);
  });

  testWidgets('item detail shows element badges + single sell badge', (
    t,
  ) async {
    final item = p.allItems.firstWhere((i) => i.sellPrice.isNotEmpty);
    await t.pumpWidget(wrap(ItemDetailScreen(item: item)));
    await t.pump();
    expect(t.takeException(), isNull);
    expect(find.byIcon(Icons.sell_outlined), findsOneWidget);
    expect(find.byIcon(Icons.payments_outlined), findsNothing);
  });

  testWidgets('synergy row tap opens SynergyDetailScreen', (t) async {
    final gun = p.allGuns.first;
    final owned = p.ownedNamesLowerCombined;
    final statuses =
        p
            .getSynergiesFor(gun.name)
            .map(
              (s) => SynergyStatus(
                synergy: s,
                missing: s.missingFor(owned),
                active: false,
              ),
            )
            .toList();
    if (statuses.isEmpty) return;
    await t.pumpWidget(
      wrapScroll(
        EntitySynergiesView(
          statuses: statuses,
          currentName: gun.name,
          ownedLower: owned,
        ),
      ),
    );
    await t.pump();
    expect(t.takeException(), isNull);
    expect(find.byType(ScaleButton), findsWidgets);
    await t.tap(find.byType(ScaleButton).first);
    await t.pumpAndSettle();
    expect(find.byType(SynergyDetailScreen), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
