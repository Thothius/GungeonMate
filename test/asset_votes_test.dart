import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/services/asset_votes.dart';

/// Asset Viewer vote store — persistence round-trip + export payload.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('catalog covers fonts, backgrounds and avatars with stable ids', () {
    final cat = AssetVotes.catalog();
    expect(cat.where((e) => e.category == 'font').length, greaterThan(10));
    expect(cat.where((e) => e.category == 'bg').length, 60); // 46 wp + 14 splash
    expect(cat.where((e) => e.category == 'avatar').length, greaterThan(50));
    // Every asset has a unique vote id.
    final ids = cat.map((e) => e.id).toSet();
    expect(ids.length, cat.length);
    // Fonts carry a bundled family; images carry a path — never both/neither.
    for (final e in cat) {
      expect(e.fontFamily != null || e.imagePath != null, isTrue,
          reason: '${e.id} has no renderable asset');
    }
  });

  test('votes persist across instances', () async {
    final a = AssetVotes();
    await a.load();
    await a.setVote('font:dmSans', 'yay');
    await a.setVote('bg:wp_07.webp', 'nay');

    final b = AssetVotes();
    await b.load();
    expect(b.voteFor('font:dmSans'), 'yay');
    expect(b.voteFor('bg:wp_07.webp'), 'nay');
    expect(b.voteFor('avatar:the_paradox'), isNull);
  });

  test('clearing a vote removes it', () async {
    final a = AssetVotes();
    await a.load();
    await a.setVote('avatar:uni_1', 'yay');
    await a.setVote('avatar:uni_1', null);
    expect(a.voteFor('avatar:uni_1'), isNull);
    expect(a.yayCount, 0);
  });

  test('export json lists every asset with verdicts + counts', () async {
    final a = AssetVotes();
    await a.load();
    await a.setVote('font:anton', 'yay');
    await a.setVote('bg:wp_01.webp', 'nay');

    final j = a.toExportJson();
    expect(j['app'], 'GungeonMate');
    final assets = j['assets'] as List;
    expect(assets.length, AssetVotes.catalog().length);
    final anton = assets.firstWhere((x) => x['id'] == 'font:anton');
    expect(anton['verdict'], 'yay');
    expect(anton['category'], 'font');
    final counts = j['counts'] as Map;
    expect(counts['yay'], 1);
    expect(counts['nay'], 1);
    expect(counts['unrated'], assets.length - 2);
  });

  test('corrupt prefs json starts clean, not crash', () async {
    SharedPreferences.setMockInitialValues({'asset_votes_v1': '{oops'});
    final a = AssetVotes();
    await a.load();
    expect(a.voteFor('font:anton'), isNull);
  });
}
