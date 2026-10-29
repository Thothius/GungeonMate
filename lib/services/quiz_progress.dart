import 'package:shared_preferences/shared_preferences.dart';

/// Persists Gungeonmaster Quiz progress locally — best streak per chest
/// tier, completion flags, and runs played. Lazily loads SharedPreferences
/// on first use; all reads are synchronous after [ensureLoaded].
class QuizProgress {
  QuizProgress._();
  static final QuizProgress instance = QuizProgress._();

  static const _kBest = 'quiz_best_';
  static const _kCompleted = 'quiz_completed_';
  static const _kRuns = 'quiz_runs_';

  SharedPreferences? _prefs;

  Future<void> ensureLoaded() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  int bestStreak(String tier) => _prefs?.getInt('$_kBest$tier') ?? 0;
  bool isCompleted(String tier) =>
      _prefs?.getBool('$_kCompleted$tier') ?? false;
  int runsPlayed(String tier) => _prefs?.getInt('$_kRuns$tier') ?? 0;

  /// Live-saves the streak high-water mark during a run so quitting or
  /// dying mid-run never loses the best streak. Cheap — only writes when
  /// the value actually beats the stored best.
  Future<void> recordStreak(String tier, int streak) async {
    await ensureLoaded();
    if (streak > bestStreak(tier)) {
      await _prefs!.setInt('$_kBest$tier', streak);
    }
  }

  /// Records a finished run: bumps runs played, sets the completion flag
  /// on a flawless clear, and returns true when a new best was set.
  Future<bool> recordRun(
    String tier,
    int streak, {
    required bool flawless,
  }) async {
    await ensureLoaded();
    final newBest = streak > bestStreak(tier);
    if (newBest) {
      await _prefs!.setInt('$_kBest$tier', streak);
    }
    if (flawless && !isCompleted(tier)) {
      await _prefs!.setBool('$_kCompleted$tier', true);
    }
    await _prefs!.setInt('$_kRuns$tier', runsPlayed(tier) + 1);
    return newBest;
  }

  /// Test hook — drops the cached prefs so mock values re-read.
  void resetForTest() => _prefs = null;
}
