# Gungeon Mate — Version History

All production APK builds are archived in `builds/` with proper version labeling.

**Format:** `gungeon-mate-v{MAJOR}.{MINOR}.{PATCH}.apk`

---

## v0.9.1 — The Road to v1.0.0 Pre-Release Consolidation (June 18, 2026)
**File:** `gungeon-mate-v0.9.1.apk`
**Size:** ~33.0 MB
**Build:** 34

### Pre-Release Version Scheme Reset
- **V0.9.1 Alignment** — Realigned and consolidated the companion features into version `0.9.1`, laying the stable foundation for our upcoming official `v1.0.0` launch in July.
- **Open Source and Free** — Declared the project completely free for all Enter the Gungeon fans.

### Full Companion Capabilities
- **Tactical Real-time Tracking** — Live inventory tracking, active co-op multiplayer sync (Bluetooth & Wi-Fi Direct), dual-telemetry tactical grid layouts, dynamic visual customizers, and deep Enter the Gungeon lore.

---

## v2.3.0 — The Chrono Customizer & Compact Dashboard Overhaul (June 16, 2026)
**File:** `gungeon-mate-v2.3.0.apk` / `GungeonMate-v2.3.2.apk`
**Size:** 32.9 MB (Full Internet connectivity restored!)
**Build:** 36

### Universal Customization Style Lab
- **Universal Settings** — Extracted particle density sliders, custom type dropdowns, and hypnotic backdrops out of the theme chooser screen, integrating them globally inside the universal Appearance Tab (Theme & font) of Settings.
- **Dynamic Swiping Previews** — Fixed a major compact page-swipe preview bug in the Theme Picker Screen. Swiping cards now instantly updates the active app background, dynamic overlays, and particle streams live in the background, allowing a complete, interactive preview before committing.
- **Premium Active Theme Indicator** — Redesigned the Active Theme Settings launcher into a modern, color-bordered gradient card complete with live-glowing color beads that display the theme's core primary/secondary colors in real-time.
- **Hypnotic Backdrop Visibility** — Automatically sets scaffold backgrounds to transparent when `hypnoticBgEnabled` is active, allowing flowing backdrop animations to shine through cleanly on all views instead of being blocked by solid backgrounds.
- **Font Dropdown Style Isolation** — Rendered each font option in the dropdown picker using its own literal `f.textStyle` to prevent selected fonts from taking over the list and create an elegant visual preview gallery.

### Co-op Multiplayer Core Sync
- **Local Multiplier Routing Fix** — Resolved a major co-op bug where Player 2 (Sidekick) adding items/guns through the Quick Add FAB locally would incorrectly apply those additions to Player 1's local inventory slot. Additions now dynamically route to `_currentPage == 1 ? PlayerSlot.coop : PlayerSlot.main`.

### Dashboard Visual Enhancements
- **Collapsible Active/Passive Pills Panel** — Converted the active status pills row into an interactive collapsible panel. If a player amasses more than 6 passives (Piercing, Homing, Armor, HP max ↑, Revive), the list dynamically collapses, appending a beveled `+ N MORE` tactile trigger to prevent vertical screen bloat.
- **Clean Cooldown reduction Label** — Changed the flat capsule stats label from `'CD RED'` to a clean and intuitive arrow `'CD ↓'`.
- **Quick Add Search Clear** — Associated a robust `TextEditingController` with the Quick Add modal search, enabling the clear (X) suffix icon and auto-clearing inputs on adding items.

### Android Core Integration
- **Internet Permission Injection** — Added the vital `<uses-permission android:name="android.permission.INTERNET" />` inside the release `AndroidManifest.xml`. This immediately restores network capability, allowing dynamic Google Font downloads and rendering all weapon, item, and shrine pixel-art network sprites with perfect resolution.

---

## v2.1.0 — Mascot & Tactical Stats UI/UX Enhancements (June 16, 2026)
**File:** `gungeon-mate-v2.1.0.apk`
**Size:** 32.8 MB
**Build:** 33

### Mascot Layout Shift Elimination
- **Positioned Speech Bubbles** — Replaced conditional widget column insertion with a beautiful, static-height `Stack` featuring a floating `Positioned` speech bubble. The main dashboard elements never shift or jump when the Mascot speaks or transitions quotes.

### Information-Dense Tactical Stats Grid
- **Split-Panel Layout** — Re-architected the `tacticalStats` grid mode from a centered icon with empty margins to an elegant dual-column telemetry interface.
- **Real-Time Telemetry** — The left side highlights the pixel art icon, while the right side displays high-contrast colored stats (Damage, Magazine, Reload, Max Ammo for guns; Curse, Coolness, Recharge, Duration for items).

### Local Multiplayer Core Bug Fixes
- **Robust PIN Suffix Discovery** — Corrected a critical issue where an empty or unset PIN code on the Sidekick would trigger a false-negative match during Nearby Connections host scanning, completely blocking connection.
- **Consistent Handshake Validation** — Normalized both local and remote PIN code values to null before checking parity in `_onHello`, preventing handshaking timeouts and unauthorized connection alert false-positives when reconnecting saved/restored co-op sessions.

---

## v2.0.0 — The Ultimate Font & Responsive Grid Layouts Overhaul (June 14, 2026)
**File:** `gungeon-mate-v2.0.0.apk`
**Size:** 32.7 MB (Universal Google Fonts integrated dynamically!)
**Build:** 32

### Dynamic Google Fonts Integration (66 Handpicked Fonts)
- **Visual Genre Catalog** — Purged heavy local font assets to clean up memory, and integrated **66 beautiful Google Fonts** handpicked for bullethell and rogue-crawler visual styles.
- **Dynamic Font Previews** — The Font selection dropdown dynamically renders each option in its *actual* letterforms, transforming the setting into an interactive typographic showcase.
- **Failsafe System Fallbacks** — All dynamic fonts fall back gracefully to the offline Enter the Gungeon pixel font if internet is unavailable or DNS queries timeout.

### 4 Responsive Grid-Based Display Layouts
- **ChoiceChip Selection** — Swap instantly between **4 distinct, refined grid layouts** in Settings to focus on different information densities.
- **Classic Periodic** — The default periodic table layout (3-4 columns) with icons and small name cards.
- **Tactical Stats** — Squeezes 4-5 high-density columns with slightly smaller icons, explicit dps/cooldown badges, and 1-line condensed names.
- **High-Def Gallery** — 2-3 massive icon display slots focusing on pure Gungeon pixel art and overlaid transparent name ribbons.
- **RPG Bag** — Flat horizontal double-column cards (1-2 columns) showcasing giant bold item titles, detailed category tags, and stats inline.

### zero-latency Redraws
- **ValueListenable Grid Refreshes** — Grid structures are wrapped in a global `ValueListenableBuilder<VisualPrefs>` to trigger instantaneous, stutter-free redraws whenever layout mode or size settings change.

---

## v1.9.0 — Lean Mobile Optimization & Instant-Search Autocomplete (June 14, 2026)
**File:** `gungeon-mate-v1.9.0.apk`
**Size:** 25.2 MB (Saved ~5MB of bloated assets & code!)
**Build:** 31

### Instant-Search Bottom Sheet
- **Ultra-Fast Autocomplete** — Added a bottom sheet directly connected to the dashboard FAB. Type 2 characters, see relevance-ranked items instantly, and add with a single haptic-vibrating tap without changing screens or breaking gameplay flow.
- **Relevance Ranking** — Prioritizes exact matches, starts-with matches, then contains matches so search queries are resolved instantly with minimal keystrokes.
- **Ownership State Detectors** — Displays "OWNED" indicators or instant "ADD" buttons directly inline.

### Lean Mobile Footprint
- **Feature Pruning** — Purged heavy, legacy NPC Dialogue engine, Winchester targets minigame simulator, and Ammonomicon tome reader to slim down app bundle size, code surface area, and asset memory.

### Physical Accelerometer Sway
- **Hardware Tilt Vectors** — Configured dynamic tilt streams in `sensors_plus` to inject x/y hardware gravity sway into all 12 custom particle painter presets, giving an organic 3D parallax feel to all themes.

### Clean UI & Transitions
- **Native Material Routers** — Swapped broken page flipping animations for standard Material routes, ensuring no screen bleeds or overlap glitches.
- **External Launcher Fallbacks** — Migrated in-app webviews to direct, fast external browser launching for `wiki.gg` references.

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
