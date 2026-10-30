# Gungeon Mate — Agent Notes

> Project root: `X:\GungeonMate` (moved 2026-10-29 — formerly
> `X:\MEDIA SILO\APPS\GungeonMate`, and before that `X:\apps\GungeonMate`;
> both old paths are now gone). App code lives in `X:\GungeonMate\gungeon_mate`.
> Always work in this path.

## Agent coordination (mandatory)
- **Multiple agents share `master`.** Read `AGENT_STATUS.md` (root repo)
  first, claim a free slot per AC1, and keep it updated (Files in
  progress, Uncommitted, Last board update); release + Session Log row
  at end (AC1–AC7).
- **Attribution:** see the "Commit Attribution & Domains" section on the
  board. Current split — SUPPORT (Devin): phases/splits/`mp_*`/SDK/
  tests/releases (prefixed commit subjects). Ammonomicon agent: codex,
  item detail, `*.json` data (unprefixed subjects — please adopt a
  `codex:`/`data:` prefix).
- When another agent's dirty files exist in the tree, use explicit
  `git add` paths — never bare `git add -A` (an `-A` sweep already
  caught in-flight codex work once).
- **Two independent repos:** root `X:\GungeonMate` →
  `github.com/Thothius/game-roomian-battler.git` (docs/coordination);
  app `gungeon_mate/` → `github.com/Thothius/GungeonMate.git` (code).
  `gungeon_mate/` is gitignored in root repo.
- gh CLI authed as `Thothius` (HTTPS remotes). If push fails:
  `gh auth setup-git` (full path: `C:\Program Files\GitHub CLI\gh.exe`).
- Sole active agent → work on `master`, no worktree needed (AC5d exception).
- Commit style: descriptive sentence (recent log style). Commit after each
  task (S7). Never `git checkout --`/`git restore` dirty files (S1).
- Root repo has uncommitted `AGENT_STATUS.md` (my slot claim) + untracked
  `9unis.jpg` (NOT mine — don't commit it without asking).
- App repo: in sync with `origin/master` (v3.2.1 `3cd8b10` pushed).
  Stash list cleared 2026-10-29 (all entries were stale/superseded WIPs).
  Worktrees under `.worktrees/` pruned same day — 4 slot branches deleted
  after their content was confirmed landed in the v3.2.1 squash.

## Bug tracker & known issues
- `docs/USER_BUG_LIST.md` — canonical tracker (B1–B4). Log confirmed bugs,
  move fixed entries to Fixed with SHA.
- Baseline green: `mp_protocol_v3` surprise-fx regression was fixed when
  the WIP landed (verified all-pass 2026-10-29).
- Open deferred: TIERS test regression (test-side, `browse_synergies`),
  synergy-scan recompute-per-build perf, browse row overflow ≤500px,
  MP first-endpoint mis-pair race, host-gone hint, `�` mojibake in JSONs.
- Feedback plan (`docs/FEEDBACK_PLAN_2026-10-28.md`): items 1–7 triaged.
  Gunderfury DPS + Junkan name-gate + Payday toggles since fixed
  (UI_HEALTH §1). Wakelock shipped. Item `effect`/`ammonomicon_entry`
  still unsurfaced in detail UI (item 5); XtG wiki-text filter (item 6).

## Release checklist (version bump = ALL in lockstep)
`pubspec.yaml` version · `lib/utils/asset_paths.dart` kAppVersion ·
`assets/data/changelog.json` prepend · `VERSION_HISTORY.md` prepend ·
`main_menu_screen.dart` ALL `vX.Y.Z` literals (3+ spots).
`version_lockstep_test` enforces sync. APK build: `flutter build apk
--release` (non-blocking, poll) → copy to `..\app-releases\gungeon-mate-vX.Y.Z.apk`.

## Coding standards highlights
- Ponytail: smallest correct diff, reuse first, no unasked abstractions.
- `dispose()` every controller/timer; `context.mounted` before overlays.
- No GridView/ListView inside PageView; compact paged grids for >8 items.
- Fixed-height text needs maxLines/overflow/FittedBox (1.4× text cap).
- `Center`/`Align` without heightFactor in bottomNav = blank-body landmine.
- flair.* tokens not raw colors; Sliver lists; haptics; BoxFit.contain in
  fixed-height SizedBox; await persistence before pops.
- Bughunt own work with proof (analyze output, grep counts) before done.
- Docs/skills: `.devin/skills/{beautify-flutter,flutter-animations,
  motion-design}`, `.devin/workflows/{pre-session,post-session,
  release-build,verify-data}` (verify-data for guns/items/synergies.json
  edits: `python gungeon_mate/tools/data_integrity.py`).

## App overview
- Flutter companion for *Enter the Gungeon* — v3.2.0+160 (Oct 2026).
- Android-first; Windows/Linux video via media_kit (drop-in, no API change).
- Offline: all game data ships in `assets/data/*.json` (239 guns, 270 items,
  395 synergies, shrines, bosses, enemies, gungeoneers, themes, changelog).
- `pubspec.yaml` version field is the single version source
  (`version_lockstep_test` enforces sync with `kAppVersion` in
  `lib/utils/asset_paths.dart` + VERSION_HISTORY).

## Architecture map
- `lib/providers/run_provider.dart` (~2k lines) — central `ChangeNotifier`.
  Master data + `RunState` + 18 special-item trackers (Robot, Gunther,
  Polaris, Gunderfury, Evolver, Shellegun, Chamber Gun, Platinum Bullets,
  Iron Coin, Spice, Metronome, Sprun, Boxing Glove, Cigarettes, Huntress,
  Gun Soul, Ser Junkan, Triple Gun). Autosaves via `_scheduleSave()`.
- `lib/services/mp_session.dart` — session facade. Bridges MpSync ↔ UI
  callbacks (`onSurpriseReceived`, `onStartRun`, chat/emote/dice), event log.
- `lib/services/mp/mp_link.dart` — Nearby Connections transport (BT/WiFi-Direct).
- `lib/services/mp/mp_sync.dart` — protocol routing: snapshot broadcast
  (debounced), hello-retry, request/gift state, dedup sets, Main-authoritative
  shared-state deltas (Sidekick sends `MpSharedStateDelta`, Main re-broadcasts).
- `lib/models/multiplayer_messages.dart` — sealed `MpMessage` wire protocol.
  `encode()` injects `'type'`; subclasses' `toJson()` must NOT include it.
  Name-only gun/item refs; peers re-resolve against local asset JSON.
  Two modes via different Nearby serviceIds: classic ↔ paradox cannot pair.
- `lib/services/app_theme.dart` (~4.7k lines) — palettes (9 + Palette Maker),
  fonts, particles, glows. `displayedMode` lets studio preview re-skin the
  whole app live.
- `lib/screens/` — home, active_run, browse, codex (+6 special codex pages),
  settings, experience_studio, quiz/, paradox/paradox_flow, mp_connect/lobby.
- `lib/widgets/` — active_run/ (player_page, dashboards, dice_roll,
  stat_sheets…), paradox/ (chat_sheet incl. `SurpriseSheet`, surprise_overlay,
  avatar_frame, paradox_bar, pause_overlay), dashboards/, item_detail/.

## Key conventions
- Provider + ChangeNotifier throughout; no codegen, no freezed.
- `Responsive.factor(context)` (`sf`) scales every dimension.
- `GoopText` instead of `Text` (Goopian language mode support).
- `EmoteSpriteCatalog` — `:key:` tokens → inline sprites (chat parses them).
- Haptics via `lib/services/haptics.dart`; reduced-motion respected.
- Tests: `test/` has ~45 files incl. full MP protocol/reliability suite.
  Run: `flutter test`. Lint: `flutter analyze` (flutter_lints).

## Toolchain (verified 2026-10-29)
- Flutter 3.29.0 / Dart 3.7.0 at `C:\src\flutter\bin` (`flutter.bat`).
  NOT on bash PATH — use `export PATH="$PATH:/c/src/flutter/bin"` or
  call `C:/src/flutter/bin/flutter.bat` via PowerShell. `X:\flutter` is
  a stale PATH entry; dir does not exist.
- Baseline: `flutter analyze` = 21 minor issues, all in test files
  (unused imports, underscore local names) — zero errors.
- Baseline: `flutter test` = **all pass** (verified 2026-10-29 post-move:
  ~424 tests, ~4 skipped). The `mp_protocol_v3` surprise-fx failure was
  fixed when the WIP landed.

## Landed: Surprise fx extension (was uncommitted WIP on 2026-10-29)
Files: `multiplayer_messages.dart`, `mp_session.dart`, `surprise_overlay.dart`.
- `MpSurprise` gained `fx` field ('bulletrain'|'heartsburst'|'explosion'
  overrides; empty = preset's own fx). `sendSurprise` threads it through.
- Overlay paints the 3 new fx; sprite card enlarged 64→140px.

### Suspect spots in the WIP (check when fixing)
1. Wire key renamed `sprite` → `spriteKey`: NOT backward-compatible forward —
   new build → old peer drops the sprite (old `fromJson` only reads `sprite`).
   Backward read handled via `j['spriteKey'] ?? j['sprite']`.
2. `MpSurprise.toJson()` now emits `'type': 'surprise'` + always-includes
   empty fields — redundant (`encode()` injects type) and breaks the
   "toJson has no type field" contract documented on `MpMessage`.
3. `fx` has **no sender yet** — nothing calls `sendSurprise(fx: …)`.
4. Custom surprise hint says "optional `:icon:`" but text is never parsed
   into `spriteKey` — token renders literally in the card. Chat DOES parse
   `:key:` (chat_sheet `_buildContent`), surprise card does not.
5. Preset fx map lives in `_SurpriseCard._presetContent` (surprise_overlay);
   sender sheet presets are a separate tuple list in `SurpriseSheet`
   (chat_sheet) — keep in sync if presets change.
