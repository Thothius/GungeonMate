# Gungeon Mate — Version History

All production APK builds are archived in `builds/` with proper version labeling.

**Format:** `gungeon-mate-v{MAJOR}.{MINOR}.{PATCH}.apk`

---

## v0.9.8 — Great UI Condensation & Galaxy Home Screen (June 19, 2026)
**File:** `gungeon-mate-v0.9.8.apk`
**Build:** 40

### Simplified Particle Settings
- **Clean Particle Options** — Stripped particle settings to just Type, Count, and Size Scale. Removed emitters, rotation, gravity vortex, flicker, subtle mode, and touch sparkles.

### Swipe-to-Select Pickers
- **Wallpaper Mode Picker** — Replaced dropdown with a horizontal swipe picker showing icons and labels for Theme Default, Custom Still, and Custom Animated.
- **Still & Animated Wallpaper Pickers** — Swipe through available wallpapers with live name display and animated scaling.
- **Font Family Picker** — Swipe through all 60+ fonts with a live preview showing the font name and a sample Gungeon phrase in the actual font styling.

### Settings Reorganization
- **Wallpaper Section Moved Up** — Relocated the Wallpaper & Parallax Engine Lab above particles and typography for faster access.
- **Condensed Layout** — Removed redundant sections and consolidated the menu for a cleaner, more focused experience.

### Galaxy Always on Home
- **Home Screen Galaxy** — The swirling Galaxy animated background now always plays on the Home/Inventory screen, creating an immersive cosmic atmosphere.
- **No Particles on Home** — All particle effects, touch sparkles, and hypnotic backgrounds are suppressed on the Home screen for a clean, focused view.
- **Screen-Aware Rendering** — Added a static screen-index notifier so ThemeOverlay knows which tab is active and renders backgrounds accordingly.

### Enhanced Readability
- **Stronger Scrim Overlay** — Added a gradient darkening layer that activates when any wallpaper or the Galaxy background is active, ensuring foreground panels and text remain crisp.

### Swipe-Only Theme Picker
- **Pure Palette Selection** — Removed all option rows, tuning panels, and customization controls from the Theme Picker. It is now a clean swipe-to-preview palette selector only.

---

## v0.9.7 — Wallpaper & Gyroscopic Parallax Engine Lab (June 19, 2026)
**File:** `gungeon-mate-v0.9.7.apk`
**Size:** ~38.4 MB
**Build:** 39

### Custom Wallpaper Collections
- **19 Exclusive Still Wallpapers** — Bundled 19 gorgeous high-fidelity pixel-art scenes depicting Gungeon chambers, weapons, and characters directly in application assets.
- **Seamless Live Loops** — Packaged 3 high-fidelity 8-second animated background loops (Vortex Galaxy, weapons racks, sewer red jelly) for beautiful background ambiance.

### Gyroscopic Parallax Engine
- **Hardware-Accelerated 3D Parallax** — Integrated a dynamic rendering system that sways the still wallpaper's offset based on smoothed gyroscope accelerometer readings.
- **Intelligent Bounds Scaling** — Scaled the wallpaper sways slightly (1.06x) to completely eliminate any edge cropping during device rotation, with a handy toggled switch.

### Robust Fail-safes & Vignettes
- **Still-Placeholder Fallbacks** — Created a robust system that cross-fades or fallbacks to the still version of a loop during initialization, guaranteeing a smooth UX on all devices.
- **Legibility Masking Overlay** — Maintained our dark radial vignette gradient overlay above the wallpapers to dim the backgrounds, guaranteeing 100% readability.

---

## v0.9.6 — Inventory Density & Legibility Control Lab (June 19, 2026)
**File:** `gungeon-mate-v0.9.6.apk`
**Size:** ~33.1 MB
**Build:** 38

### Flexible Inventory Grid Density
- **Adjustable Periodic Column Count** — Style Lab and Settings now feature a periodic grid column count setting, allowing users to seamlessly scale the inventory layout between 2 (compact), 3 (medium), or 4 (dense) columns based on their device aspect ratio.
- **Active Grid Auto-Layout** — Calibrated both the Main Active Run inventory and the Favourites inventory to automatically adjust column widths and spacing on layout changes.

### Premium Subtle Particle Mode
- **Advanced Legibility Toggle** — Introduced a premium switch that halves background particle counts across all custom presets and theme-specific backdrops, maximizing text readability in low-light environments while retaining the floating ambiance.
- **Backdrop Optimizations** — Re-coded all real-time custom painters for Preset backdrops (including Gold Dust, Toxic Bubbles, and Cosmic Rift) to dynamically clamp particle limits instantly.

### Unified Customization Tuning
- **Integrated Display & Text Scaling** — Consolidated all grid layout, periodic columns, and inventory text scaling options under a single 'Inventory Grid & Display Tuning' section.
- **Synchronized Style Panels** — Re-organized the Premium Theme Picker's Customization Tuning cards to stay perfectly aligned with the main Settings screens.

---

## v0.9.5 — Premium Particles & Global Goop Conversion Update (June 19, 2026)
**File:** `gungeon-mate-v0.9.5.apk`
**Size:** ~33.1 MB
**Build:** 37

### Premium Particle Overhaul
- **Categorized Groups** — Redesigned background custom particles and grouped them into:
  - **Elements** — Ember (Fire), Frost (Ice), Toxic (Poison), Lightning (Spark), Rainbow (Prismatic).
  - **Metal** — Golden Shells, Brass Casings, Steel Sparks.
  - **Bone** — Necrotic Skull, Skeletal ashes, Tombstone Dust.
- **Dynamic 3D depth & Winds** — Implemented physical colored background wind paths and wind-swept physics, with custom Z-depth parallax scale factors.

### Global Goop conversion
- **Synchronized Ciphers** — Wrapped all search database rows, item/gun headings, and shrine detail cards in GoopText, converting dynamically in perfect unison.

---

## v0.9.4 — Animated Backgrounds & Special HUD Refactor Update (June 19, 2026)
**File:** `gungeon-mate-v0.9.4.apk`
**Size:** ~33.1 MB
**Build:** 36

### Special Inventory HUDs
- **Separate Weapon Dashboards** — Gunderfury, Triple Gun, and Evolver are now fully rendered as separate, detailed dashboard panels right after the main player character DASH, identical to Ser Junkan!

### Procedural Animated Backgrounds
- **CRT Static & Cyber Glitch** — Added real-time CRT Analog Static and Cyber Glitch Screen backdrops, painted entirely procedurally via hardware-accelerated canvas commands.
- **Central Readability Mask** — Overlayed a deep radial gradient vignette over the center and corners of all animated backgrounds, ensuring that all foreground card text, labels, and icons remain 100% readable.

### Settings Tooltip Calibration
- **showDuration Extension** — Configured settings-screen tooltips to remain visible for a full 5 seconds instead of vanishing too quickly.

---

## v0.9.3 — General UX Refinement & System Polish Update (June 19, 2026)
**File:** `gungeon-mate-v0.9.3.apk`
**Size:** ~33.1 MB
**Build:** 35

### Huntress tabbed HUD
- **Huntress HUD Drawer** — Converted the Huntress dashboard into an information-dense sliding tab panel featuring three interactive sub-HUDs:
  - **Junior II Digs** — Showcases room-clear dig probabilities (dynamically doubling to 10% when carrying Baby Good Mimic) and includes a critical growling Mimic chest detection warning.
  - **Crossbow Breakpoints** — A complete health mapping table of early floor enemies (Bullet Kin, Shotgun Kin, Rubber Kin) and how many 26-damage Crossbow shots are needed to eliminate them.
  - **Key Economy** — Tactical walkthrough guide to Oubliette (Sewer) and Abbey of the True Gun entry costs, conditions, and rewards.

### Seamless Run Termination
- **Unified End & Disconnect** — Refactored co-op session teardown to allow Sidekicks to directly select "End Run & Disconnect" in their options menu. A single action ends the run, notifies the host, clears local states, and returns the player to the main menu.

### Gunfortuna's Duel Refinements
- **UI & Scale Improvements** — Enriched the popup constraints to a majestic 440px width, scaled dice to a giant 72x72 face with size-34 typography, corrected DIEL to DUEL, and designed a beautiful glowing amber result banner for solo rolls.
- **Organic 3D Bobbing Physics** — Programmed a sine-wave vertical translation offset into the rolling matrix, causing the dice to float and bob organically while tumbling.

### Bouncy scale-button mechanics
- **Premium Click UX** — Wrapped all primary Main Menu category cards (Local Run, Multiplayer, Customize), the Tailor mascot tap area, and active Gunfortuna dice triggers in our haptic ScaleButton wrapper. Touching these elements physically scales them down with satisfying spring bounce-backs and automatic lightweight touch haptics.

### Shrines & Settings UX Polish
- **Cleanse First** — Automatically sorts the Cleanse Shrine to the absolute top of the picker list, making it instantly accessible for wiping Curse states.
- **Centered Large Graphics** — Enriched the Shrine activation sheet layout, centering the descriptions and blowing the icon size up to a beautiful, giant 120x120 container with shadow casts.
- **explicit Heart Penalty Indicators** — Integrated a direct, high-contrast warning badge alert (💔 PENALTY COST: -1 HEART CONTAINER (LIFE -1)) for the Angel and Blood shrines.
- **Appearance Compaction** — Re-organized all font-style, font-size, inventory-size, and font-bias preferences inside a single, beautifully bordered Card with thin 32px slider track profiles, and completely deleted the redundant HELP & TIPS tab from settings.

### Mascot Dialogue Expansion
- **The Tailor Speaks** — Expanded our central main menu hauling mascot (The Tailor) with 16 new highly detailed, lore-rich Gungeon quotes. Tapping him now triggers random insights regarding Master Rounds, secret floors (Oubliette/Abbey), chest mimic alerts, S-Tier black chests, and weapon reload mechanics.

### Goopian & The Sponge 🧽 translation modes
- **Professor Goopton's Cipher** — Added a core "Interface Language" dropdown card in Settings under Run Language. Choosing "Goopian" converts the main menu mascot quotes and all weapon/item titles into unreadable cipher symbols.
- **Matrix Deciphering Stream** — When Goopian is active, a glowing interactive "The Sponge" 🧽 button floats inside the Active Run app bar. Activating it triggers a real-time, character-by-character digital translation stream that magically decodes the symbols into English from left-to-right (and encodes them in reverse on toggle-off!).

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
