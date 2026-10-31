# Reference screenshots — real app on Flutter web

Captured 2026-10-31 from `flutter build web --release` at 390x844 viewport
(iPhone-class compact phone), Minimalist default theme, v3.3.0.

Purpose: ground truth for the design-lab mocks. Compare lab views
against these when unifying the designed vs. actual UI.

| File | View |
|------|------|
| ref-01-home.png | Main menu |
| ref-02-character-select.png | Gungeoneer picker |
| ref-03-active-run.png | Active run (Marine, fresh run) |
| ref-04-browse.png | Browse, ALL mode |
| ref-05-item-detail.png | Item detail (Ancient Hero's Bandana) |
| ref-06-codex-skeleton-loading.png | Ammonomicon — STUCK on skeleton loaders on web |
| ref-07-quiz.png | Quiz home (chest tiers) |
| ref-08-settings.png | Settings |

Note: the Ammonomicon tab never finished loading on web during capture
(skeleton shimmer persisted >10s). Also captured incidentally: a quiz
session "CORRECT!" reveal — same root dir, deleted. MP surfaces fail on
web (nearby_connections plugin unsupported — expected).
