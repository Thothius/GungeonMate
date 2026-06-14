# Gungeon Mate — Version History

All production APK builds are archived in `builds/` with proper version labeling.

**Format:** `gungeon-mate-v{MAJOR}.{MINOR}.{PATCH}.apk`

---

## v1.8.5 — Theme Overlays & Independent Grid Scaling (June 14, 2026)
**File:** `gungeon-mate-v1.8.5.apk`
**Size:** 30.7 MB
**Build:** 30

### Theme Backdrops Fixed
- **Transparent Scaffolds** — Set `scaffoldBackgroundColor` in `ThemeData` to transparent and painted `f.scaffold` color as the absolute bottom layer of `ThemeOverlay`. This prevents solid scaffolds from blocking underlying trippy background and particle layers!
- **Dual Layer Effects** — Separated trippy hypnotic background layers and particle engines so they can now render simultaneously if both are enabled.

### Beautiful Mobile Webview & Offline Fallbacks
- **Clean In-App Wiki.gg Webview** — Injected custom JS and CSS to strip away global navigation, headers, sidebars, ads, and footers from wiki.gg inside the app for a native look.
- **Themed Offline Fallback View** — Designed a stunning, dark neon 'WIKI UNREACHABLE' screen that gracefully handles network and DNS connection failures, giving options to retry or view offline info.

### Independent Scaling
- **Grid Tile Font Size Slider** — Added a separate 'Inventory Tile Font Size' slider in Settings to adjust grid item title text (10.0-18.0 pt) independently of global scale, preventing clipping and squishing.

---

## v1.8.4 — The Lore & Dialogue Update (June 14, 2026)
**File:** `gungeon-mate-v1.8.4.apk`
**Size:** 30.7 MB
**Build:** 29

### NPC Dialogue Overhaul
- **Interactive NPC Conversations** — talk to Bello, Winchester, The Vampire, and more with chamber-aware responses.
- **5 Secret Delivery Quests** — hidden storylines for Flynt, Vampire, Sell Creep, Professor Goopton, and Cursula.
- **Bello's Secret Cabinet** — deliver Gungeon Anomalies to unlock a permanent 30% shop discount.
- **Cursula Flirting Engine** — playful, personality-matched dialogue lines.
- **Typewriter Animation** — adjustable speed (Instant, Fast, Normal, Slow) with haptic ticks.
- **High-Entropy Randomization** — combined chamber-specific and random-tip dialogue pools to avoid repetition.

### Visual & UI Polish
- **Trippy Backgrounds** — hypnotic animated backdrops (Edge Drip, Glint Sheen, Elastic Wobble) layered behind all UI.
- **Interactive Main Menu Mascot** — tap the Tailor mascot for randomized Gungeon-themed speech bubbles.
- **Enlarged NPC Sprites** — 200%+ scale for accessibility with stabilized dialogue layouts.
- **Favorite Star Repositioned** — moved to top-right of item detail header for better UX.
- **Dog Interaction Counters** — persistent pet and treat counters for Junior II.

### Technical Fixes
- Fixed `FontWeight.black` → `FontWeight.w900` build error.
- Fixed missing `.dart` extension in Flutter material import.
- Restored Favorites menu item in dashboard popup menu.
- Wiki links now point to `enterthegungeon.wiki.gg`.

---

## v1.7.2 — Gunfortuna Dice Skins (June 12, 2026)
- Customizer dropdown for dice skins (Classic, Gold, Frost, Molten, Void, Toxic).
- Huntress HUD fix — restored collapsed inventory grid visibility.
- Dog strip grounded to horizontal movement with animated speech bubbles.
- Filter UI upgrades with double-height category tags.

---

## v1.7.0 — Interactive Winchester Campaign (June 12, 2026)
- 10-level chamber-based campaign replacing standard target shooting.
- Dual-thumb controls (BAM! fire button + analog aiming stick).
- Dog treat cookie throw with active pathfinding.
- Baby Good Mimic synergy — purple-tinted twin companion dog with independent AI.

---

## v1.5.0 — The Robot Overhaul & Persistence (May 2026)
- No-Hearts armor engine for The Robot.
- Junk Damage Recycler — live +5% damage per Junk item.
- 3D card-flip rotations with spring-back easing.

---

## v1.0.0 — Core GungeonMate Release (May 2026)
- Rich offline item database (239 guns, 270 items, 395 synergies).
- Single-device persistence via SharedPreferences.
- Local multiplayer Bluetooth/Wi-Fi sync via Google Nearby Connections.
- Winchester's Minigame — full billiard-physics target shooting simulator.
- 8 Shrines reference with auto-detected curse/coolness deltas.

---

**All versions archived for reference and rollback capability!** 📦✨
