import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gungeon_mate/models/ammonomicon_entry.dart';
import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/models/multiplayer_messages.dart';
import 'package:gungeon_mate/models/player.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/widgets/paradox/paradox_player_panel.dart';
import 'package:gungeon_mate/widgets/paradox/surprise_overlay.dart';
import 'package:gungeon_mate/screens/ammonomicon_detail_screen.dart';
import 'package:gungeon_mate/screens/neo_skeuo_lab_screen.dart';

void main() {
  late RunProvider p;
  late MpSession mp;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    p = RunProvider();
    await p.loadData();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    p.startNewRun(Gungeoneer(name: 'Marine'));
    mp = MpSession.placeholder();
  });

  Widget wrap(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: p),
      ChangeNotifierProvider.value(value: mp),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );

  // ── ParadoxPlayerPanel ──────────────────────────────────────────

  for (final slot in PlayerSlot.values) {
    testWidgets('ParadoxPlayerPanel renders for $slot', (t) async {
      await t.pumpWidget(wrap(ParadoxPlayerPanel(slot: slot)));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
      expect(find.byType(ParadoxPlayerPanel), findsOneWidget);
    });
  }

  // ── SurpriseOverlayHost ─────────────────────────────────────────

  testWidgets('SurpriseOverlayHost renders child and shows surprise card', (
    t,
  ) async {
    await t.pumpWidget(
      wrap(
        const SurpriseOverlayHost(child: Center(child: Text('body'))),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('body'), findsOneWidget);

    // Fire a preset surprise through the session callback the host
    // registered in initState.
    mp.onSurpriseReceived?.call(
      const MpSurprise(preset: 'love', fx: 'heartsburst'),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('I LOVE YOU'), findsOneWidget);
    // Card auto-dismisses on a 3.2s Timer — flush it.
    await t.pump(const Duration(seconds: 4));
    expect(t.takeException(), isNull);
  });

  testWidgets('SurpriseOverlayHost renders custom surprise with sprite', (
    t,
  ) async {
    await t.pumpWidget(
      wrap(const SurpriseOverlayHost(child: SizedBox())),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));

    mp.onSurpriseReceived?.call(
      const MpSurprise(
        preset: 'custom',
        text: 'CUSTOM TEXT',
        spriteKey: 'love',
        fx: 'explosion',
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    await t.pump(const Duration(seconds: 4));
    expect(t.takeException(), isNull);
  });

  // ── AmmonomiconDetailScreen ─────────────────────────────────────

  for (final section in [
    AmmonomiconSection.guns,
    AmmonomiconSection.items,
    AmmonomiconSection.npcs,
  ]) {
    testWidgets('AmmonomiconDetailScreen renders ${section.name} entry', (
      t,
    ) async {
      final entry = AmmonomiconEntry(
        name: 'Test ${section.name} Entry',
        category: 'Test',
        description: 'A test description for coverage.',
        icon: '',
        wikiUrl: '',
        tips: const ['tip one', 'tip two'],
      );
      await t.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: p),
            ChangeNotifierProvider.value(value: mp),
          ],
          child: MaterialApp(
            home: AmmonomiconDetailScreen(entry: entry, section: section),
          ),
        ),
      );
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
      expect(find.byType(AmmonomiconDetailScreen), findsOneWidget);
    });
  }

  testWidgets('AmmonomiconDetailScreen surfaces shrine + combat stats', (
    t,
  ) async {
    final shrine = AmmonomiconEntry(
      name: 'Ammo Shrine',
      category: 'Shrines',
      description: 'A shriny description.',
      icon: '',
      wikiUrl: '',
      tips: const ['Refills ammo, but increases curse.'],
      shrineMessage: 'Deal with the Devil',
      shrineEffect: 'Refills the ammo of all weapons.',
      shrineCurse: 3.5,
      shrineCoolness: 0,
    );
    await t.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: p),
          ChangeNotifierProvider.value(value: mp),
        ],
        child: MaterialApp(
          home: AmmonomiconDetailScreen(
            entry: shrine,
            section: AmmonomiconSection.shrines,
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(t.takeException(), isNull);
    expect(find.text('SHRINE'), findsOneWidget);
    expect(find.textContaining('CURSE +3.5'), findsOneWidget);
    expect(find.textContaining('Deal with the Devil'), findsOneWidget);

    final enemy = AmmonomiconEntry(
      name: 'Test Enemy',
      category: 'Enemy',
      description: 'desc',
      icon: '',
      wikiUrl: '',
      collisionDamage: 0.5,
    );
    await t.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: p),
          ChangeNotifierProvider.value(value: mp),
        ],
        child: MaterialApp(
          home: AmmonomiconDetailScreen(
            entry: enemy,
            section: AmmonomiconSection.enemies,
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(t.takeException(), isNull);
    expect(find.textContaining('BODY DMG: 0.5'), findsOneWidget);
  });

  // ── NeoSkeuoLabScreen (dev sandbox — smoke only per H-L9) ───────

  testWidgets('NeoSkeuoLabScreen smoke renders', (t) async {
    await t.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: p),
          ChangeNotifierProvider.value(value: mp),
        ],
        child: const MaterialApp(home: NeoSkeuoLabScreen()),
      ),
    );
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(t.takeException(), isNull);
    expect(find.byType(NeoSkeuoLabScreen), findsOneWidget);
  });
}
