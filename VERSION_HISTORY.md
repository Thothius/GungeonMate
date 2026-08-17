# Gungeon Mate — Version History

All production APK builds are archived in `../app-releases/` with proper version labeling.

**Format:** `gungeon-mate-v{MAJOR}.{MINOR}.{PATCH}.apk`

---

## v1.9.22 — 🎨 Home Screen Vortex Video + Character Grid Fix (August 2026)
**Build:** 99

> UI polish: removed BULLET HELL heading, fixed character grid to 3 columns, swapped home background to the actual vortex video.

### Changes
- **Removed BULLET HELL heading:** The animated "BULLET HELL EDITION" wobble+burn banner was removed from the home screen for a cleaner look. The `_BulletHellHeading` widget class and all related code was deleted.
- **Character grid fixed to 3 columns:** Character select screen now always uses 3 columns (was 3/4/5 based on screen width). With 9 gungeoneers, this gives a uniform 3x3 grid on all devices.
- **Home screen vortex video:** Swapped the home screen background from `wp_anim_01_galaxy.mp4` (galaxy wallpaper) to `gungeonmate-animation-02.mp4` (the actual orbiting purple portal vortex). Opacity boosted from 0.55 to 0.85, black overlay reduced from 0.62 to 0.35. Removed the redundant `GungeonFallAnimation` canvas vortex that was replicating the video in code.
- **Version strings synced** to v1.9.22.

---

## v1.9.21 — 📋 Items Wiki Audit Round 5 (Final) — Table Techs, Active Items, Companions, Rings (August 2026)
**Build:** 98

> Final pass of items wiki comparison: 23 more item effects enriched with specific values. Completes the items accuracy audit.

### Changes
- **FIX (BUG-080) — 23 final items with vague effects enriched:**
  - Table Tech Heat: 5 tile radius, 10 second duration
  - Table Tech Money: 40% chance to drop 1-4 coins per table flipped
  - Table Tech Rocket: 30 damage on impact + 30 explosion damage
  - Table Tech Shotgun: 10 homing bullets, 6 damage each, 4 bounces
  - Bomb: 60 damage to nearby enemies
  - Molotov: 4 DPS for 4 seconds
  - Magazine Rack: 10 second duration, guns need 1+ ammo
  - Charm Horn: 10 second charm duration
  - Aged Bell: 5 second freeze
  - Potion of Gun Friendship: +30% damage, 2x fire rate, -70% reload, 10x knockback
  - Cluster Mine: 60 damage per mine
  - Chaff Grenade: 10 second stun
  - Daruma: recharges by damaging enemies
  - Orbital Bullets: wall-hit trigger, bounce fallback at max
  - Ring of Chest Vampirism: half a heart, includes Mimics
  - Cartographer's Ring: 50% chance, no secret rooms
  - Chaos Bullets: 10% pierce/bounce/status, 25% beam per second
  - Gundromeda Strain: affects bosses too
  - Baby Good Shelleton: 12.5 DPS laser
  - Honeycomb: 12-20 bees, 3 damage + 1/s for 2s
  - Enraging Photo: 4 second duration
  - Blue Guon Stone: 33% enemy shot speed reduction, 5 seconds
  - Portable Table Device: triggers Table Tech effects

---

## v1.9.20 — 📋 Items Wiki Audit Round 4 — Bullet Upgrades, Guon Stone, Table Tech (August 2026)
**Build:** 97

> Fourth pass of items wiki comparison: 12 more item effects enriched with specific values.

### Changes
- **FIX (BUG-079) — 12 more items with vague effects enriched:**
  - Frost Bullets: chance higher for slower-firing weapons
  - Devolver Rounds: devolves into Arrowkin, beam guns gain double damage chance
  - Hungry Bullets: blue bullets eat projectiles within 1.5 tiles, +10% dmg/size per bullet, cap 80%, doubles beam damage
  - Magic Bullets: 4% chance to transmogrify into chickens, multiplied by gun's effect chance scalar
  - Zombie Bullets: 33% chance to refund 1 ammo, no effect on beam weapons
  - Chance Bullets: shots from other guns don't consume ammo from source gun
  - Katana Bullets: curse +1, 100% chance for beam guns on kill, 50%/s beam double damage
  - Table Tech Sight: 3 second duration, grammar fix (triples not triple)
  - Green Guon Stone: 20% heal chance, 50% if damage would have killed
  - Ruby Bracelet: 30 damage to nearby enemies, doesn't destroy guns
  - Mustache: Bello's shop 15% cheaper
  - Ice Bomb: 8 damage

---

## v1.9.19 — 📋 Items Wiki Audit Round 3 — Ammolets, Companions, Active Items (August 2026)
**Build:** 96

> Third pass of items wiki comparison: 14 more item effects enriched with specific values.

### Changes
- **FIX (BUG-078) — 14 more items with vague effects enriched:**
  - Copper/Frost/Uranium Ammolet: stun 1s, 25 tile radius, 50% chance to ignite/freeze/poison
  - Lodestone Ammolet: stun 3s, 25 tile radius, 400% knockback increase
  - Wingman: homing 20-damage rockets every 5 seconds, blocks bullets
  - R2G2: bursts of 6 bullets, 5 damage each, 4 second cooldown
  - Super Space Turtle: 5 damage bullets
  - Melted Rock: 15 damage to nearby enemies
  - Singularity: 8 second duration, sucks enemies/bullets/items
  - Air Strike: 25 damage per explosion
  - Fortune's Favor: 8 second duration, repulses enemy bullets
  - Proximity Mine: 60 damage
  - Bumbullets: bee every second, 3 damage + 1/s for 2 seconds, no ammo cost
  - Crutch: slight homing towards enemies

---

## v1.9.18 — 📋 Items Wiki Audit Round 2 — Bullet Upgrades, Synthesizers, Ammolets (August 2026)
**Build:** 95

> Second pass of items wiki comparison: 11 more item effects enriched with specific values.

### Changes
- **FIX (BUG-077) — 11 more items with vague effects enriched:**
  - Gilded Bullets: up to 100% damage at 500 shells (formula-based)
  - Platinum Bullets: fire rate doubles every 250s to max triple, damage doubles every 500s to max triple
  - Stout Bullets: 50% larger bullets, 12.5%-75% more damage at close range, halved after 7 tiles, -30% bullet speed
  - Ammo Synthesizer: 10% chance to regain 5% of max ammo on kill
  - Armor Synthesizer: 10% chance to gain armor on room clear without damage
  - Heart Synthesizer: 20% chance to gain half heart on room clear without damage (if not at full health)
  - Master of Unlocking: 20% chance to give free key on room clear if no damage taken
  - Ring of Chest Friendship: 50% increased chest chance, halves D-tier, redistributes to C/B
  - Chaos Ammolet: 50% chance to ignite/poison/freeze, stun 1s, 25 tile radius, extra blank
  - Antibody: 50% chance to heal extra half heart on any healing
  - Bloody 9mm: 8% chance per second for homing/piercing/bouncing bullet

---

## v1.9.17 — 📋 Items Wiki Accuracy Audit — Vague Effects Enriched with Specific Mechanics (August 2026)
**Build:** 94

> Items-focused wiki comparison audit: 33 item effects enriched with wiki-accurate mechanics and values.

### Changes
- **FIX (BUG-073) — 13 passive items with vague effects:** Added specific values from wiki.gg:
  - Ballistic Boots: +2 movement speed
  - Shotga Cola: +1.5 movement speed
  - Shotgun Coffee: +1.2 movement speed
  - Bionic Leg: +1.5 movement speed, grants armor
  - Military Training: 20% reload, 17% spread, 16.7% charge time
  - Battle Standard: 80% companion/charmed enemy damage
  - Coin Crown: 10% chance, 5 shells, no damage taken
  - Gold Ammolet: 60 damage, 25 tile radius, stun, extra blank
  - Wolf: 5 damage per bite
  - Bullet Idol: 45 damage to all enemies in room
  - Eyepatch: 35% damage, 65% shot spread
  - Unity: 2% flat damage from non-equipped guns
  - Book of Chest Anatomy: 45% pickup, 50% item, 5% same quality

- **FIX (BUG-074) — 6 bullet upgrades with missing percentages:**
  - Charming Rounds: 7.5% chance to charm
  - Hot Lead: 20% chance to ignite
  - Homing Bullets: 20% chance to home
  - Irradiated Lead: 50% chance to poison for 2.5s
  - Explosive Rounds: 8.5% chance, 25 damage
  - Shadow Bullets: 15% chance for extra projectile

- **FIX (BUG-075) — 4 active items with missing durations:**
  - Stuffed Star: 9s duration, pits/traps still harm
  - Double Vision: 10s duration, reduces accuracy
  - Bullet Time: 3s duration
  - Potion of Lead Skin: 6s duration

- **FIX (BUG-076) — 10 more items with vague effects:**
  - Pig: sacrifices itself, removes item from inventory
  - Heart of Ice: 8-12 ice bullets, freeze effect
  - Cat Bullet King Throne: flight, roll direction bullets
  - Table Tech Rage: 3s duration
  - Omega Bullets: final two shots (not just final shot)
  - Shock Rounds: connects bullets, damages in path
  - Snowballets: further travel (not just "as they travel")
  - Angry Bullets: no ammo cost
  - Macho Brace: double damage (not just "more powerful")
  - Turkey: same gun requirement

### Wiki Comparison Results (verified correct)
- Heart of Ice quality C with sell_price 41 — confirmed (multi-quality item, always sold at A price)
- All N/A sell_price items — confirmed correct (cannot be dropped/sold)
- All quality N items with undefined sell_price — confirmed (quest items)
- Frost Bullets, Devolver Rounds — wiki doesn't list specific percentages, left as-is

---

## v1.9.16 — 🔧 Playwright QA Fixes — Ticker Crash, Version Strings, Synergy Typo (August 2026)
**Build:** 93

> 3 bugs found via Playwright full-views QA sweep and fixed. 24 screens tested, 0 JS errors after fix.

### Changes
- **FIX (BUG-059) — Critical ticker crash:** GungeonHeader used SingleTickerProviderStateMixin with 2 AnimationControllers, crashing the app after character select. Fixed to TickerProviderStateMixin.
- **FIX (BUG-060) — Stale version strings:** Main menu had 4 hardcoded 'v1.9.11' strings while pubspec was v1.9.15. Updated all 4 to 'v1.9.15'.
- **FIX (BUG-061) — Synergy plural typo:** Browse pill said 'synergys' instead of 'synergies'. Fixed pluralization logic.

---

## v1.9.15 — 📋 Wiki Accuracy Audit — Number Formatting, Recharge Consistency, Vague Effects (August 2026)
**Build:** 92

> Wiki comparison audit: 5 formatting and content bugs fixed across guns and items.

### Changes
- **FIX (BUG-068) — Number spacing:** 10 guns had spaces inside number values (e.g. `"16. 6"` → `"16.6"`) in DPS, damage, and spread fields. Affected Flare Gun, Lower Case r, Mailbox, Makarov, Pea Shooter, Shellegun, Sling, Starpew, Trashcannon, Triple Gun.
- **FIX (BUG-069) — Double degree symbols:** 3 guns had `°°` in spread field — Crescent Crossbow, Gunbow, M1911. Fixed to single `°`.
- **FIX (BUG-070) — Recharge time consistency:** 7 active items had inconsistent `recharge_time` — 6 had `"-Use"` (truncated from `"Single-Use"`) and 1 had `"Single Use"` (missing hyphen). All normalized to `"Single-Use"`. Affected Duct Tape, Meatbun, Medkit, Ration, Spice, Supply Drop, Weird Egg.
- **FIX (BUG-071) — Reload time suffix:** 10 guns had `reload_time` missing `"s"` suffix (e.g. `"1.2"` → `"1.2s"`). Affected Barrel, Cold 45, Devolver, Directional Pad, Evolver, Flash Ray, Railgun, Sawed-Off, Strafe Gun, Vorpal Gun.
- **FIX (BUG-072) — Vague item effects:** 3 items had vague effect text missing key mechanics, confirmed by wiki.gg comparison:
  - Galactic Medal of Valor: now includes "30% more damage", "halves reload time and shot spread", "cannot be dropped"
  - Number 2: now includes "movement speed +2, damage +41%"
  - Gungeon Pepper: now includes "5 damage per second"

### Wiki Comparison Results (stats verified correct)
- AK-47, Void Marshal, Cold 45, Flare Gun, Makarov, M1911 — all stats match wiki.gg exactly
- 12 items with "N/A" sell_price — all confirmed correct (cannot be dropped/sold)
- 14 items with undefined sell_price — all quality N quest items (intentional)
- Unusual recharge_time values ("Cannot be used", "None", "Toggled", "Room cleared", "3 Uses") — all confirmed correct per wiki

---

## v1.9.14 — 📋 Deep Data Audit Round 2 — Synergy Ref Tokens, Infinite Range/Shot Speed Stats (August 2026)
**Build:** 91

> Round 2 of deep audit: 11 synergy ref tokens cleaned, 56 gun range fields set to ∞, 6 beam weapon shot_speed set to ∞.

### Changes
- **FIX (BUG-065) — Synergy ref tokens:** 11 synergy effects had `' .'` and `' ,'` patterns from stripped wiki ref tokens. All cleaned (Behold!, Cormorant, Fairy Bow, Five O'Clock Somewhere, Kung Fu Hippie Rappin' Surfer, Pinker Guon Stone, Resourceful Indeed, Rubenstein's Monster, Shield Night, Tears of Blood, Whiter Guon Stone).
- **FIX (BUG-066) — Empty gun range fields:** 56 guns had `"range": ""` — all now set to `"∞"` (infinite range). Confirmed against wiki.gg which shows `[Infinity.png]` for these guns. Includes AK-47, Bullet Bore, Deck4rd, Eye of the Beholster, Pitchfork, and 52 more.
- **FIX (BUG-067) — Empty beam shot_speed:** 6 beam weapons had `"shot_speed": ""` — all now set to `"∞"` (instant beam travel). Abyssal Tentacle, Gamma Ray, Life Orb, Moonscraper, Mourning Star, Raiden Coil.

### Audit Notes
- Remaining empty stat fields (shot_speed for 18 non-beam guns, spread for 25 guns, force for 17 guns) are confirmed correct — the wiki does not list these stats for those guns.
- Casey quote "Batting .50" is intentional (baseball batting average reference), not a formatting bug.

---

## v1.9.13 — 📋 Deep Data Audit — Stripped Ref Tokens, Empty Gun Classes, Missing Icons (August 2026)
**Build:** 90

> Deep audit found 3 data quality issues: 31 stripped ref tokens, 12 empty gun classes, 3 missing icons.

### Changes
- **FIX (BUG-062) — Stripped ref tokens:** 22 guns and 9 items had `' .'` and `' ,'` patterns caused by wiki ref tokens being stripped during data import. All 31 entries cleaned.
- **FIX (BUG-063) — Empty gun classes:** 12 guns had empty `class` fields. Populated with wiki-verified values: A.W.P. (RIFLE), Alien Sidearm (PISTOL), Anvillain (CHARGE), Balloon Gun (FULLAUTO), Bee Hive (SILLY), Big Iron (PISTOL), Big Shotgun (EXPLOSIVE), Blunderbuss (CHARGE), Brick Breaker (SILLY), Budget Revolver (SHITTY), Bullet (PISTOL), Cold 45 (ICE).
- **FIX (BUG-064) — Missing icons:** Master Round I, Master Round II, and Rusty Sidearm had empty icon URLs — now populated with correct wiki image URLs.

### Audit Summary (no issues found)
- 0 invalid synergy references (all 395 synergies reference valid guns/items)
- 0 duplicate synergy/gun/item names
- 0 unresolved wiki tokens remaining
- 0 missing type/quality/wiki fields
- 0 active items missing recharge_time (all 67 complete)
- 14 items with no sell_price — all quality N quest items (intentional, unsellable)
- 291 synergies without custom icons — expected (use generic Synergy.png)
- 20 unreferenced guns + 54 unreferenced items — confirmed via wiki (no active synergies exist)

---

## v1.9.12 — 📋 Data Integrity — Truncated Text, Empty Gun Notes, Synergy Name Fix (August 2026)
**Build:** 89

> 3 data bugs fixed: truncated item effect, 12 empty gun notes, synergy name mismatch.

### Changes
- **FIX (BUG-056) — Truncated effect:** Briefcase of Cash effect text was `'Grants 250 and 3 .'` — restored to `'Grants 250 coins and 3 Hegemony Credits.'`
- **FIX (BUG-057) — Empty gun notes:** 12 guns (AK-47, Derringer, M1911, Machine Pistol, Magnum, Makarov, Regular Shotgun, Thompson Sub-Machinegun, Trank Gun, Void Marshal, Vulcan Cannon, Winchester Rifle) had empty `notes` fields — populated with wiki-sourced descriptions.
- **FIX (BUG-058) — Synergy name:** 'Thermal Imaging' corrected to official wiki name 'Thermal Imagine'.

---

## v1.9.11 — ♿ Accessibility + UX Polish — Tap Targets, Tooltips, Haptics (August 2026)
**Build:** 88

> 5 UI bugs fixed: tap targets, tooltips, haptics, SafeArea, responsive text.

### Changes
- **FIX (BUG-051) — Tap targets:** 3 IconButtons with sub-minimum tap targets fixed — delete session (16px→44px), MP diagnostics close (20px→44px), favorite toggle (36px→44px).
- **FIX (BUG-052) — Tooltips:** 21 IconButtons across 11 files now have tooltips for screen reader accessibility.
- **FIX (BUG-053) — Haptics:** 10 dashboard GestureDetector controls now call `Haptics.light()` on tap — Robot toggles, Junkan junk +/-, Gunderfury/Triple Gun/Evolver +/-.
- **FIX (BUG-054) — SafeArea:** Emote bottom sheet now uses `useSafeArea: true` — no more risk of system nav bar obscuring emote buttons.
- **FIX (BUG-055) — Responsive text:** Stats detail screen large stat value (fontSize 52) wrapped in `FittedBox(scaleDown)` — shrinks gracefully on narrow screens / high text scale.

---

## v1.9.10 — 🔧 Synergy Icons + Dashboard Fixes + Gun Type Data (August 2026)
**Build:** 87

> 6 bugs fixed: synergy icon coverage, dashboard expansion logic, Robot dashboard fields, gun type data.

### Changes
- **FIX (BUG-022) — Synergy icons:** All 395 synergies now have icons. 108 unique sprites + 287 using the generic blue synergy arrow as fallback. No more letter placeholders.
- **FIX (BUG-046) — Dashboard expansion:** Junkan + 3 special gun dashboards (Gunderfury, Triple Gun, Evolver) — fixed inverted `_expanded` variable. Renamed to `_collapsed`, dashboards now start expanded, chevron points correct way.
- **FIX (BUG-047) — Robot dashboard:** Added 4 missing tracked fields: Armor counter (+/-), Fireplace Extinguished toggle, Battery Bullets Synergy toggle, Fuse Disarmer toggle. All were persisted in RunProvider but had no UI.
- **FIX (BUG-048) — Rad Gun type:** Empty `type` field set to "Semiautomatic".
- **FIX (BUG-049) — Gunderfury type:** Garbage `type` field set to "Variable". Removed `isGunderfury` special case in `gun_stats.dart`.
- **FIX (BUG-050) — Type normalization:** Deck4rd + Mr. Accretion Jr. non-standard type variants normalized to "Semiautomatic".

---

## v1.9.9 — 🧹 Code Hygiene — Dead Code + Silent Error Logging (August 2026)
**Build:** 86

> Dead 1S branches removed, silent error catches now log, version desync fixed.

### Changes
- **CLEANUP — Dead 1S branches:** Removed 20+ defensive `1S` quality normalisation branches across 9 files (run_provider, gun, item, quality_badge, periodic_tile, browse_pills, game_icon, inventory_list_row, sort_picker). Data no longer contains `1S` values (fixed in BUG-020).
- **FIX (BUG-032) — Silent error logging:** All 42 `catch (_) {}` blocks now log errors via `debugPrint` with file-specific tags. SharedPreferences failures are no longer invisible.
- **FIX — Version desync:** pubspec bumped from 1.9.5 to 1.9.9+86 to match changelog. All version strings in main_menu updated.

---

## v1.9.8 — 🎨 Theme Palette Assessment Fixes (August 2026)
**Build:** 85

> Theme palette quality fixes from critical assessment — distinct color identities, correct particle defaults, visible remix hue shifts.

### Changes
- **FIX — Oubliette theme:** Primary (#39FF14) and headline (#CCFF00) were identical to Bullet Hell — changed to sickly sewer green (#64DD17) and pale toxic lime (#B2FF59). (Hidden theme — code quality fix.)
- **FIX — Cult of Gundead theme:** Primary was harsh pure #FF0000 — softened to styled #FF1744 (Material red A400). (Hidden theme — code quality fix.)
- **FIX — Robot's Core particles:** Default was brassCasings (brass shells — doesn't fit cyber aesthetic) — changed to cosmicStars (cyan/gold/white twinkling stars) to match the teal/green circuit identity.
- **FIX — Forge Master remixes:** Ember (+12°) and Inferno (-12°) were too subtle — increased to +25° and -25°. Magma kept at +35°.

---

## v1.9.7 — 🎨 Compact Theme Picker + Particle Visibility Fix (August 2026)
**Build:** 84

> Theme picker massively compacted. Particles now visible in picker.

### Changes
- **REDESIGN — Theme picker:** Full-screen immersive pages replaced with compact horizontal swipeable card carousel (100px tall). Dot indicator replaces circle strip.
- **FIX — Particle visibility:** Old immersive pages had opaque scaffold backgrounds blocking particles. New compact cards use semi-transparent backgrounds so particles show through.
- **CLEANUP — Removed dead _DashboardPreview widget.**

---

## v1.9.6 — 🌀 Portal Vortex Animation (August 2026)
**Build:** 84

> Home screen portal vortex + last_played_character persistence.

### Changes
- **NEW — Portal vortex animation:** Looping custom-painted animation on home screen — bright glow orbits in a circular path, pulsing brighter at top/bottom. Deep purple radial gradient, vortex rings, comet-like particle trail. 14-second cycle.
- **NEW — last_played_character persistence:** Survives run end and app kill, updates on character pick for SP or MP.

---

## v1.9.5 — ⚙️ Settings Reorganization + Particle Studio + Menu Groups (August 2026)
**Build:** 84

> Settings reorganized into 3 logical tabs. All particle controls unified in theme picker. Active run menu grouped with labels.

### Changes
- **NEW — 3 settings tabs:** APPEARANCE (theme, typography, glow, inventory layout), GAMEPLAY (dialogue, dice, shrines, event log), APP (MP, session, reset, changelog, dev, danger zone). Was 2 tabs with mixed concerns.
- **NEW — Particle Studio in theme picker:** Expandable panel with all advanced particle controls (enable, count, size, opacity, glow effect, line links, bounce). Collapsed by default. One place for all particle customization.
- **NEW — Grouped popup menu:** Active run gear menu now has labeled section headers (BROWSE, ACTIONS, SESSION, END, SETTINGS) instead of a flat 12-item list.
- **REFACTOR — AppearanceTab:** Renamed from ThemeVisualsTab. Removed particle section (→ theme picker) and dice section (→ GameplayTab).
- **REFACTOR — AppTab:** Renamed from CombinedRunAppTab. Removed dialogue card (→ GameplayTab).
- **NEW — GameplayTab:** New settings tab with dialogue card, dice style panel, shrine tile, event log tile.
- **CLEANUP:** Removed unused helper methods, imports, and dead code from refactored tabs.

---

## v1.9.4 — 📱 Responsive Polish — Final Pass (August 2026)
**Build:** 83

> Final responsive scaling pass across remaining screens.

### Changes
- **FIX — Browse screen tab bar:** Tab height (52→52*sf) and icon sizes (20→20*sf) now scale with screen width.
- **FIX — Item detail screen:** Back/Wiki/Action button sizes (68→68*sf) and Back label font (16→16*sf) scale with screen width.
- **FIX — Multiplayer lobby:** Start Hosting / Find Host button height (54→54*sf) scales with screen width.
- **FIX — Settings theme visuals:** All 4 action buttons (Choose Theme, Particle Preset, Glow Color, Font) height (56→56*sf) and theme label font (20→20*sf) scale with screen width. Font picker label font (16→16*sf) scales too.
- **FIX — Item detail header:** Item/gun name title font (28→28*sf) scales with screen width.
- **FIX — Codex special page headers:** All 6 special page title fonts (28→28*sf) scale with screen width.
- **FIX — Character select grid:** Column count adapts — 3 on <360dp, 4 on <500dp, 5 on 500dp+ (was fixed at 4).

---

## v1.9.3 — 📱 Responsive Layout for Bigger Screens (August 2026)
**Build:** 82

> UI elements now scale proportionally to screen width so they look right on bigger phones.

### Changes
- **NEW — Responsive scaling helper (`Responsive`):** Baseline is 400dp (OnePlus 8). Scale factor clamped to 0.85x–1.25x based on screen width. Used across main menu, theme picker, periodic tiles, and codex grid.
- **FIX — Periodic grid tiles:** DPS/DMG/RNG badge font sizes, item name, and type subtitle now scale with screen width. Removed the `textScaler` clamp (0.8–1.05) that prevented fonts from growing on bigger screens.
- **FIX — Main menu buttons:** Local Run and Multiplayer button heights (54→54*sf), font sizes (16→16*sf), and icon sizes now scale. Palette button and Changelog button also scale.
- **FIX — Theme picker:** Theme dot circles (22/32px → scaled), theme name (28→28*sf), tagline, flavour description, and Apply button (52→52*sf) all scale with screen width.
- **FIX — Codex grid:** Column count now adapts — 3 columns on <360dp, 4 on <500dp, 6 on 500dp+ (was fixed at 4 regardless of screen size).

---

## v1.9.2 — 🎨 Particle Customization + Codex Nav + Fixes (August 2026)
**Build:** 81

> Particle color schemas, speed control, Megrim font repositioned, critical MP particle fix, codex scroll/nav fixes, beam gun data corrections.

### Changes
- **NEW — 16 Particle Color Schemas:** Inferno, Glacier, Toxic, Void Storm, Gilded, Rainbow, Monochrome, Blood Moon, Synthwave, Forest, Candy, Steel, Sunset, Abyss, Preset Default, Theme Match. All work with every theme and palette. Selectable from the theme picker as a horizontal pill strip with mini color preview dots. Theme Match uses the active flair's primary/secondary/glow colors.
- **NEW — Particle Speed Control:** 5 discrete steps — Very Slow (0.3x), Slow (0.6x), Normal (1.0x default), Fast (1.6x), Very Fast (2.5x). Speed multiplier applied to particle delta-time in `ParticleField`. Selectable from the theme picker.
- **NEW — Megrim font repositioned:** Moved from position 42 to position 2 in the `AppFont` enum, right after the Gungeon default font.
- **CRITICAL FIX — MP particles disappearing:** Entering a multiplayer run caused particles to disappear until app restart. Root cause: `ThemeOverlay.currentScreenIndex` was set via `addPostFrameCallback` in `home_screen.dart`, leaving a stale frame where the home-screen galaxy + contrast backing + readability scrim stayed painted over particles. Nothing forced a repaint until the user minimized/restored the app. Fix: set `currentScreenIndex` synchronously in `build()`.
- **FIX — Codex special page scroll:** All 6 special codex pages (Paradox, Gunslinger, Bullet Hell, Drake, Challenge Mode, Rat) wrapped their `CustomScrollView` in a nested `Scaffold` inside `Expanded`, blocking scroll. `Scaffold` wrapper removed — `CustomScrollView` now returns directly.
- **FIX — Codex nav strip:** Compact 56px height (was 76), `BouncingScrollPhysics` with `ScrollDecelerationRate.fast` for smooth & quick horizontal scrolling. Category tiles made more compact (icon 18px, font 11px, padding 12x8).
- **FIX — Beam gun reload_time:** 4 beam guns (Demon Head, Disintegrator, Gamma Ray, Raiden Coil) had `reload_time` `'/A'` instead of `'N/A'`. All corrected.
- **FIX — Gun data corrections:** BSG damage prefixed with `Impact:`, range set to `∞`. Composite Gun damage prefixed with `Uncharged:`, range set to `∞`. Dark Marker range set to `∞`, damage `40 x2` → `40x2`.

---

## v1.9.1 — 🔥 BULLET HELL EDITION (August 2026)
**Build:** 80

> Hotfix follow-up to v1.9.0. Critical particle/glow fix, dashboard panel scroll fix, codex horizontal scroll, MP emotes, and more.

### Changes
- **CRITICAL FIX — Particles & glow not showing on most themes:** `kThemeParticleDefaults` only had 5 of 22 themes mapped. Themes like Bullet Hell, Lord Jammed, Resourceful Rat, and 14 others fell back to `gungeonDust` with `themeAutoOn = false`, so particles never auto-enabled. Added all 22 themes with sensible preset matches. Also added auto-glow for themes with non-transparent `glowPrimary` — a subtle 0.15 ambient glow out of the box, overridable by user's explicit `glowIntensity`.
- **FIX — Special dashboard panels no longer scroll:** All 16 special character/gun dashboards now render at full natural content height instead of being capped at 22% of screen height with `SingleChildScrollView`. Replaced fixed-height `PageView` with `AnimatedSwitcher`. Robot's damage calculator terminal removed (grew unbounded with gun count).
- **FIX — Codex categories horizontal scroll:** Replaced cramped 4-column `GridView` (10 categories wrapping to 3 rows) with horizontal scrollable `ListView` of pill-style tiles.
- **FIX — Periodic tile DMG/RANGE 50/50 split:** `_buildGunStatsBadge` now uses `Expanded(50/50)` for DMG and RANGE badges instead of `MainAxisSize.min` Row. No more overflow on wider tiles.
- **FIX — Inventory font size slider moved:** Relocated from Inventory visual category to App Typography Tuning section, next to the global Font Size slider.
- **NEW FEATURE — MP Emotes (Kiss/Slap):** Tap your own character tab in multiplayer while already viewing it to open the emote menu. Kiss: pink heart floats up on peer's screen for 6s. Slap: angry face slams down + screen shake for 2s. Purely visual, renders above all dialogs via root `Overlay`.
- **NEW CODEX — Resourceful Rat:** Thief, merchant, and secret boss. 6 sections, 24 info blocks.
- **NEW CODEX — Drake:** Serpent/Baby Dragun companion chain.
- **NEW CODEX — Challenge Mode:** All 24 modifiers from wiki.
- **POLISH — Bullet Hell heading bigger + 6s pause wobble:** Title bumped from 13px to 18px. Wobble now fires in a 2.8s burst then rests for 6s before the next fiery shake, instead of continuously wobbling.

---

## v1.9.0 — 🔥 BULLET HELL EDITION (August 2026)
**Build:** 79

> **The big one.** A branded milestone release bundling the v1.8.39 hotfixes together with the UX/visual rework (BUG-035–039) and feature upgrades under one banner. The v1.8.39 patch fixes are folded in — no separate v1.8.39 ship. See `docs/bullet_hell_edition_plan.md` for the full edition scope and styling direction.

### Changes
- **NEW FEATURE — Bullet Hell codex page:** A themed special page under the Codex tab (6th tab, fire icon). Shows the official `Bullethell_header.png` hero image with a "CHAMBER 6 / BULLET HELL" title overlay, then scrollable dark-neon sections for: Lore & Entry (access trigger, the descent), Survival — The "No Loot" Rule (resource starvation, drop reliance, high jammed rate), The Three-Loop Layout (junction 1/2/3 cards + boss door rule), Hazards & Enemies (flesh cubes, shotgrubs, environmental traps), and The Boss: The Lich (three numbered phase cards). Includes a wiki.gg external link. Built in `lib/screens/bullet_hell_codex_screen.dart`; tab wired in `codex_screen.dart`; image at `assets/images/codex/Bullethell_header.png`.
- **BUG-017 (HIGH):** `Max Pane` synergy in `assets/data/synergies.json` listed only `Glass Cannon` in its `items` array, but the effect text references both `Glass Cannon` and `Glass Guon Stone`. `matchesItems()` requires all listed items, so the synergy never flagged active. Added `Glass Guon Stone` to the array.
- **BUG-019 (HIGH):** `mp_request_listener.dart` closed the "Connection lost" drop dialog silently on reconnect — no snackbar, no haptic. Now distinguishes a real reconnect (status → `connected`/`handshaking`) from a teardown (status → `idle`/`error`) and shows a floating "Connection restored — sync resumed" snackbar with `Haptics.success()` only on the former.
- **BUG-020 (MEDIUM):** 36 entries across `guns.json` (19) and `items.json` (17) used `"quality": "1S"` instead of `"S"` — a data pipeline artifact that surfaced as "1S" in UI metadata chips. Global replace to `"S"`. Simplified the `_qualityOrder` map in `browse_screen.dart` (removed the `'1S': 0` alias).
- **BUG-035 (UX):** PeriodicTile gun panel rework — gun type now sits as a centered subtitle below the item name instead of a tiny corner tag. RANGE is now shown alongside DPS in the bottom-center badge. Tile aspect ratio adjusted to fit the new subtitle row.
- **BUG-036 (UX):** Active run HeaderMenu — "Reset P1 Items" (and "Reset P2 Items" in coop) now available as a quick action directly in the menu. Settings moved to the bottom section so the top prioritizes in-run actions. Confirm dialog shared between menu and Settings Run tab.
- **BUG-037 (UX):** Removed the Multiplayer Summary tab from the MP header — the P1/P2 header is now cleaner with just the two player tabs. Summary page code left dormant on disk.
- **BUG-038 (HIGH):** Unicorn theme particles fixed — auto-enables unicorn sparkle particles with per-palette colors. Palette selector no longer requires horizontal scrolling (all 6 visible in a wrap layout). ParticleField gained a `colorsOverride` param for per-palette color injection.
- **BUG-039 (MEDIUM):** S-tier quality badge reverted to its documented design — black pill, white letter, animated golden glow. S chest chip label and icon now white instead of dark-on-dark.
- **Feature — Stat-group tag upgrade:** Combat/Handling/Meta labels in the gun detail screen are now bigger (15px, w800) and color-coded. Each group gets a signature accent color that themes can override via `ThemeFlair.statGroupCombat/Handling/Meta`. Filled-pill header for filled-chip themes, accent-bar for minimalist themes.
- **Feature — Quick theme selection + particle streamlining:** Every visible theme now auto-binds a curated particle preset (Forge Master→embers, Robot's Core→casings, Custom→cosmic stars). Theme picker has a quick-access strip of 5 tappable theme circles + a horizontal particle preset strip for instant effect switching. Applying a theme returns to the launch point instead of kicking to home. Palette quick-launch button on the main menu.
- **Feature — Compact combined Settings:** The old 3-tab Settings (VISUALS / RUN / APP) is now 2 tabs (VISUALS / RUN & APP). The Run & App tab uses a compact 2-column grid of action tiles grouped into RUN SESSION, INVENTORY & DATA, and DANGER ZONE. Old AppTab left dormant on disk.
- **Main menu cleanup:** Removed Codex button and Settings gear from the home screen. Codex and Settings remain reachable from the active-run gear menu. Character select grid changed from 2-column to 4-column for faster picking.

### Verification (landed changes)
- `node -e JSON.parse(...)` confirms all modified JSON files are well-formed.
- `flutter analyze` on modified Dart files — see bughunt step.

---

## v1.8.19 — Dice Roll UX: Cancel, Sparkles, and VS Overflow (July 24, 2026)
**Build:** 74
**APK:** `gungeon-mate-v1.8.19.apk`

### Changes
- **MpDiceCancel protocol** — new `MpDiceCancel` message, `MultiplayerSession.onDiceCancel` callback, and `sendDiceCancel()` outgoing operation. The incoming-challenge dialog in `active_run_screen.dart` now closes if the challenger cancels before the peer responds.
- **Cancel-challenge UI** — `DiceRollDialog` shows a "CANCEL CHALLENGE" button while waiting for the peer, and `PopScope` now allows dismissal in the `challenging` state.
- **Per-die sparkle positioning** — each `DiceWidget` receives a `GlobalKey`; `DiceRollDialog` uses these plus a particle-layer `GlobalKey` to convert die center from global to particle-local coordinates so sparkles spawn exactly on the tapped die.
- **VS score overflow** — finished-duel score `Text` widgets are wrapped in `FittedBox` and nickname/dice join strings use `maxLines: 1` + `TextOverflow.ellipsis` to avoid clipping on narrow screens.
- **Analyzer cleanup** — added missing curly braces to 7 multi-line `if` bodies in `multiplayer_session.dart`; `flutter analyze` on modified files is clean.

### Verification
- `flutter analyze lib/models/multiplayer_messages.dart lib/services/multiplayer_session.dart lib/screens/active_run_screen.dart lib/widgets/active_run/dice_roll.dart` — 0 issues
- `git status` clean before release build

---

## v1.8.0 — Codebase Reorg: 5 Megafiles Split into 39 Widget Files (July 23, 2026)
**Build:** 73

### Megafile Reorganization (All 5 Phases Complete)
Split 5 megafiles totaling 17,891 lines into 39 focused widget files (2,404 lines total in original files).

**Phase 1: active_run_screen.dart (9,520 → 566 lines, 15 files)**
- widgets/active_run/: player_header, player_page, active_run_helpers, stat_sheets, sort_picker, starter_hint, dice_roll, summary_tab
- widgets/dashboards/: dashboard_swiper, robot_dashboard, junkan_dashboard, special_gun_dashboards, huntress_dashboard, compact_dashboards
- widgets/sheets/: damage_calc_sheet

**Phase 2: theme_overlay.dart (951 → 312 lines, 8 files)**
- widgets/particles/: touch_particle, ambient_glow, curse_fog, curse_breath, crimson_drip
- widgets/backgrounds/: page_frame, animated_wallpaper
- widgets/easter_eggs/: cat_throne

**Phase 3: item_detail_screen.dart (3,582 → 332 lines, 6 files)**
- widgets/item_detail/: header, gun_stats, item_body, synergies_section, destroy_banner, quick_jump_button

**Phase 4: browse_screen.dart (1,638 → 1,130 lines, 4 files)**
- widgets/browse/: any_entry, browse_pills, browse_row, toolbar_button

**Phase 5: settings_screen.dart (2,390 → 64 lines, 6 files)**
- widgets/settings/: theme_visuals_tab, run_tab, app_tab, swipe_picker, run_log_screen, debug_tab

### Verification
- flutter analyze lib/ — 0 issues
- All AnimationControllers have dispose()
- All async callbacks have mounted/context.mounted checks
- All private classes made public (removed _ prefix), super.key added

---

## v1.7.1 — UI Polish: Detail View Redesign + Damage Calc Sizing (July 23, 2026)
**Build:** 72

### Item/Gun Detail Header Redesign
- Graphic centered with no inner border — clean, aligned perfectly.
- Title centered below graphic.
- Removed quality badge circle and type label from header row.
- Quote shown as plain centered italic text (no container border).
- Rank now displayed as first colored metadata pill alongside sell price and synergy count — all centered.

### Damage Calculator
- Collapsed panel: increased padding (16/12), min-height (48), font sizes (10→11) for readability.
- Popup sheet: increased padding (20/16/20/20), header icon (22px), header font (15px), bonus pill font (14px).

### Bug Fixes (BUG-013 to BUG-016)
- Character select loadout view: taller cards (0.64 ratio), bigger in-game graphic (2px padding), 220px image height.
- Dashboard settings icon: replaced Spacer() with SizedBox(width: 6) to stop icons being pushed off-screen.
- Avatar cycling: added 1.2px padding to Container, reduced ClipRRect radius to 8.8 to keep border visible.
- Settings tab: added to bottom NavigationBar as third tab with SettingsScreen.

---

## v1.7.0 — Goopian Language + Codex Bestiary + Settings Overhaul (July 23, 2026)
**Build:** 71

### Goopian Language Mode
- Toggle between English and Goopian alien text; 600+ Text widgets across all 16 screens converted to animated GoopText translation.

### Codex Bestiary
- 146 enemies and 27 bosses added with icons, health values, and detail views sourced from wiki.gg.

### Settings Reorganization
- 4-tab layout (VISUALS, RUN, APP, DEBUG) with cleaner separation of concerns.

### Character Select Rework
- Tap avatars to flip and preview, SELECT button to confirm; fixed loadout panel overflow.

### Player Avatar Cycling
- Tap avatar on active run to cycle through static icon, in-game GIF, and animated card art.

### Other
- Shrine Icon — tap opens Shrine Picker, long-press toggles shrine tracker panel.
- Main Menu Polish — floating mascot with tilt parallax, idle float animation, compact settings gear icon.
- 18 Special Dashboards — Robot, Huntress, Junkan, Gunderfury, Triple Gun, Evolver, Shellegun, Chamber Gun, Platinum Bullets, Iron Coin, Spice, Metronome, Sprun, Boxing Glove, Cigarettes, Polaris, Gunther, Gun Soul.
- Damage Calculator — toggleable DPS terminal with per-gun breakdown and multiplier contributions.
- Multiplayer — auto-reconnect, persisted sessions, FIX LINK, state-drift protection, dice decline protocol.
- UI Polish — collapsible sections everywhere, fastRoute 150ms fade transitions on all navigation.

---

## v1.6.9 — UI Polish: Character Select, Shrine Icon, Avatar Cycling (July 23, 2026)
**Build:** 70

### Character Select
- Cards now require SELECT button press — tap avatars to flip and preview freely before confirming.
- Fixed overflow when starting loadout panel expands (SingleChildScrollView + fixed image height).

### Active Run Dashboard
- Shrine icon tap now opens Shrine Picker screen; long-press toggles shrine tracker panel.
- Player avatar cycles through 3 graphics modes on tap: static icon → in-game GIF → animated card art.
- Quick comment speech bubble wrapped in IgnorePointer to prevent intercepting icon button taps.

### Main Menu
- Settings gear icon added (compact, icon-only) next to Codex icon and Changelog button.
- Codex icon added to bottom menu row.

### Settings Screen
- Reorganized into 4 tabs: VISUALS, RUN, APP, DEBUG.
- New APP tab — Language toggle, Dialogue haptics, Custom Dice, Changelog viewer, Reset Data.
- VISUALS tab expanded — Wallpaper section and Inventory Layout section exposed.
- Run Options popup refined — removed Guides & Info, My Favourites kept, Settings entry added.

---

## v1.6.7 — Main Menu Polish: Floating Mascot + Tilt Parallax (July 23, 2026)
**Build:** 68

### Mascot Redesign
- Removed circle container (border + dark background) — The Tailor now floats freely.
- Added subtle golden glow halo via `boxShadow` (no visible border).
- Added idle float animation: 3.2s sine wave bobbing ±6px (never static).
- Added accelerometer tilt parallax: mascot drifts ±2.5px X / ±2.0px Y based on `ThemeOverlay.tiltNotifier`.
- Combined float + tilt creates a magical ocular subtle effect when moving the phone.

### Menu Button Polish
- Button height reduced 56→54 for tighter look.
- Font size 17→16, letter spacing 1→1.2 for refined typography.
- Local Run: added elevation 3 with subtle golden shadow.
- Multiplayer: border opacity tuned to 0.18 for cleaner look.
- Haptics.selection() added to both button taps.

---

## v1.6.6 — Unicorn Palette Redesign: 6 Pink/Crimson/Purple Palettes (July 23, 2026)
**Build:** 67

### Palette Overhaul
- Reduced from 7 to 6 palettes — removed Rainbow (yellow accent didn't fit).
- Replaced Aurora (green-based) with Bubblegum (pink/magenta/violet).
- Replaced Galaxy (blue/cyan-based) with Mulberry (deep magenta/purple/pink).
- All 6 palettes now use exclusively pink, crimson, purple, and bubblegum tones.

### Color Fixes on Existing Palettes
- Cotton Candy: rose pink `#F06292` replaces cyan `#00F5D4` headlineStat.
- Neon: magenta-purple `#E040FB` replaces electric teal `#00CED1`.
- Dreamy: lilac `#CE93D8` replaces sage teal `#80CBC4`.
- Sunset: powder pink `#FFD1DC` replaces golden teal `#4DB6AC`.

### New Palettes
- **Bubblegum**: scaffold `#1A0F1E`, primary `#FF80AB`, secondary `#E040FB`, stat `#B388FF`.
- **Mulberry**: scaffold `#1C0A18`, primary `#C2185B`, secondary `#9C27B0`, stat `#F06292`.

### Migration
- Old persisted palette indices ≥4 (rainbow/aurora/galaxy) are out of range and default to Cotton Candy.
- All taglines, preview data, and whimsical descriptions updated to remove teal/cyan/green references.

---

## v1.6.5 — UI Polish: Collapsible Sections + Compact Settings (July 23, 2026)
**Build:** 66

### Collapsible Synergies (Item/Gun Detail)
- `_SynergiesSection` converted from StatelessWidget to StatefulWidget with `_collapsed = true`.
- Header shows synergy count badge and active-synergy indicator (amber pill).
- Tap-to-expand with animated chevron rotation and haptic feedback.

### Collapsible Referenced-By (Item/Gun Detail)
- `ReferencedBySection` now starts with `_sectionCollapsed = true`.
- Header shows referrer count badge and animated chevron.
- Removed unused `_MasterToggle` class and helper methods (`_collapsibleGroupCount`, `_allGroupsExpanded`, `_toggleAll`).
- Removed unused `themed_section_title.dart` import.

### Curse/Coolness Detailed Views Reorder
- Live effects now appear directly under the value card (most relevant first).
- Quick actions moved below effects.
- Event log remains collapsed by default at the bottom.
- `_CoolnessEffects` "Also" section now collapsible (collapsed by default).
- `_CurseEffects` full curse effect table now collapsible (collapsed by default).
- Both converted from StatelessWidget to StatefulWidget.

### Compact Settings Menu
- `_ThemeVisualsTab` converted from StatelessWidget to StatefulWidget.
- Typography and Particle System sections are collapsible (collapsed by default) with tap-to-expand headers.
- Added `_collapsibleSectionHeader` and `_collapsibleSectionHeaderWithInfo` helper widgets.
- Reduced inter-section spacing (24→16, 20→12).
- Reduced theme card padding (18→14 horizontal, 16→12 vertical).
- Reduced font picker height (112→80).
- `_utilTile` now uses `dense: true` and `VisualDensity.compact` with smaller icons and margins.
- Removed unused `_prefSectionTitle` method.

---

## v1.6.4 — Codex Expansion: Enemies & Bosses + Home Screen Streamline (July 23, 2026)
**Build:** 65

### Codex Enemies Tab
- Added 146 enemies scraped from wiki.gg with pixel-art icons, base health values, and descriptions.
- Covers all Cult of the Gundead variants from Bullet Kin to Lord of the Jammed.

### Codex Bosses Tab
- Added 27 bosses with icons and wiki links.
- Includes all floor bosses (Bullet King, Gatling Gull, Trigger Twins, Ammoconda, Beholster, Gorgun, Cannonbalrog, Mine Flayer, Treadnaught, High Priest, Kill Pillars, Wallmonger, High Dragun) plus secret bosses (Blockner, Door Lord, Blobulord, Old King, Resourceful Rat, Agunim, Black Stache, Dr. Wolf's Monster, HS Absolution, Interdimensional Horror, Cannon, The Last Human, Lich).

### Base HP Display
- Enemy and boss detail screens now show base health values alongside their category badge.

### Home Screen Streamline
- Removed Customize and Codex buttons from the main menu — these are in-run features.
- Reduced active-run bottom navigation tabs from 4 to 2 (Inventory + Browse).

---

## v1.6.3 — Theme Picker Redesign: Dashboard Preview + Big Palette Buttons (July 23, 2026)
**Build:** 64

### Dashboard Preview
- Theme picker now shows a mini `GungeoneerHeader` mockup with portrait, stat capsules (COOL/CURSE/SYN/DPS), and sample inventory rows.
- Preview uses the theme's actual `ThemeFlair` colors (card, primary, headlineStat, chipRadius, cardRadius, numberGlowColor) so users see exactly how the theme looks on the active run screen.
- Portrait loads The Marine's local asset icon via `localGungeoneerIcon`.

### Big Palette Selector
- Replaced small `_RemixChips` text-only chips with `_PaletteSelector` — large 64px-tall tappable cards.
- Each card shows a vertical color swatch stack (scaffold/primary/accent) next to the label text.
- Active card gets a glowing border with `boxShadow`, check icon, and animated transitions.
- Unicorn palette cards show per-palette colors (via `UnicornPalette.flair`), not just the current mode's colors.
- Horizontally scrollable with `BouncingScrollPhysics` for smooth UX.

### Removed
- `_ColorDot` widget (unused after redesign)
- `_PaletteCore` class (unused after redesign)
- `_RemixChips` widget (replaced by `_PaletteSelector`)

---

## v1.6.2 — Theme-Accent Dashboard Border + Curse Sheet Polish + Menu Restructure (July 23, 2026)
**Build:** 63

### Animated Theme-Accent Dashboard Border
- `GungeoneerHeader` now has a `_borderPulseController` (4.5s reverse-repeating) that drives an `AnimatedBuilder` wrapping the card container.
- Border uses `f.primary` (theme accent) with alpha pulsing 0.15→0.40 via sine wave; matching `boxShadow` pulses blurRadius 8→14 in sync.
- Border width bumped to 1.2 for visibility. Properly disposed in `dispose()`.

### Curse Sheet UX Polish
- Replaced uneven `Wrap` with a 3×2 `Row`/`Expanded` grid for effect chips — perfect alignment on any screen width.
- Added visual 0–10 curse meter bar with gradient and scale labels.
- Added section labels: `EFFECTS AT CURRENT LEVEL`, `ADJUST CURSE`, `QUICK ACTIONS`.
- Upgraded breakdown button to full-width `OutlinedButton` with accent border.
- Standardized spacing (14/16) and bumped chip value font sizes.

### Header Menu Restructure
- Removed `use_shrine` menu item (now a dashboard button).
- Added `save_run` menu item for local runs — calls `RunProvider.saveRun()` with snackbar confirmation.
- Added public `saveRun()` method to `RunProvider` delegating to `_saveRun()`.
- Ensured `end_run` available for local runs and MP host; MP sidekick keeps `leave_mp` + `end_run`.
- Simplified redundant ternary `mpActive ? 'End Run' : 'End Run'` → `'End Run'`.

### Panel Opacity / Dimness Fix
- Settings `_utilTile`: `Colors.black @ 0.45` → `Colors.white @ 0.06`, border `0.10` → `0.15`.
- Settings MP section: same fix.
- Settings `_toggleChip`: `flair.card @ 0.35` → `0.65`, border `0.10` → `0.20`.
- Settings `_FullLogLegend`: `Colors.white @ 0.02` → `0.05`, border `0.05` → `0.10`.
- MP summary stats grid border: `Colors.white @ 0.06` → `0.12`.
- MP summary synergy panel border: `Colors.amber @ 0.12` → `0.20`.

---

## v1.6.1 — MP Summary Overhaul: Compact Stats + Collaborative Synergy Icons (July 22, 2026)
**Build:** 62

### Compact Stat Chips
- MP summary page now shows P1 (cyan) vs P2 (purple) values in a tight 3-column grid.
- Guns, items, active syns, max DPS, damage bonus, and combined coolness/curse all visible at a glance.
- Removed old `_StatComparisonRow` class — replaced by inline `_statChip` method.

### Collapsible Synergy Overview
- Synergy panel collapsed by default with tap-to-expand header.
- Shows active count and next-pickup hint when collapsed; full breakdown when expanded.
- `_synergyExpanded` state in `_MpSummaryPageState`.

### Visual Synergy Icon Pairs
- Synergy rows now display actual item/gun pixel-art icons in horizontal scroll.
- Owned items full-color with green glow; missing items greyed at 35% opacity.
- Connecting lines between paired items, colored by synergy status.
- New `_SynergyItemIcon` widget with fallback letter icon for missing assets.

---

## v1.6.0 — Unicorn Mega Theme + Sparkle Numbers + Custom Theme Editor (July 22, 2026)
**Build:** 61

### 3 New Unicorn Palettes
- Rainbow: Full spectrum pink/purple/gold with bold neon energy.
- Aurora: Northern lights green/violet on deep forest black.
- Galaxy: Deep space purple/cyan/gold on cosmic black.
- Brings the Unicorn megapack to 7 switchable palettes total.

### Sparkle Numbers + Number Glow
- All 7 Unicorn palettes now render tiny twinkling star glyphs around headline numbers.
- 4 sparkles at staggered phases (2.2s cycle) with independent opacity and scale pulsing.
- Headline numbers also get a soft coloured halo behind digits, tinted to each palette's primary.

### 4 New Particle Presets
- Unicorn Sparkles: Pink/purple/cyan star shapes with pulse glow and rotation.
- Cosmic Dust: Deep blue/violet circles with ripple rings and line links.
- Golden Sparkle: Gold/amber stars with smokey glow and slow spin.
- Rainbow Confetti: Multi-color edge shapes tumbling downward with high wobble.

### Custom Theme Editor
- Custom theme is now visible in the theme picker.
- "Customize Colors" button opens a bottom sheet with 6 color slots.
- 24 curated Gungeon colors per slot, plus a Randomize button.
- Slots: Background, Card, Primary, Secondary, Accent/Headline, Bullet.

---

## v1.5.3 — Transition Polish + Empty Dashboard Fix (July 21, 2026)
**Build:** 60

### Snappy Page Transitions
- Replaced all 12 `MaterialPageRoute` calls in `active_run_screen.dart` with custom `_fastRoute` — a `PageRouteBuilder` using 180ms fade + 0.97→1.0 scale-up with `Curves.easeOutCubic`.
- Root cause: `MaterialPageRoute` slides the new page over the old one, leaving the previous screen visible during the ~300ms transition — perceived as "ghosting" or "previous view stays for a bit."
- Fix: Fade+scale transition makes the new screen appear crisply without the old one lingering. Reverse transition is 150ms for snappy back navigation.
- Affected screens: ItemDetailScreen, StatsDetailScreen, BrowseScreen, ThemePickerScreen, FavouritesScreen, ShrinePickerScreen, EffectsSummaryScreen, CharacterSelectScreen.

### Empty Dashboard Fix
- Root cause: `_DashboardSwiper` always added `_UniversalDamageCalculatorSliver` for non-robot characters, even when `showDamageCalculator` was disabled or the player had no guns. The swiper reserves a fixed 320px height — showing 320px of empty space.
- Fix: Check `VisualPrefs.showDamageCalculator` and `player.guns.isNotEmpty` before adding the DPS calc to the dashboards list. When `dashboards.isEmpty`, the swiper returns `SizedBox.shrink()` — zero height.
- Also wrapped `_DashboardSwiper.build()` in `ListenableBuilder` for `VisualPrefs` so it rebuilds immediately when the toggle flips.

### Bughunt
- `flutter analyze`: 16 pre-existing warnings, 0 new, 0 errors.
- All 12 `MaterialPageRoute` references confirmed replaced — grep returns 0 results.

---

## v1.5.0 — Codex + Special Dashboards + Tactical Grid + Event Log (July 21, 2026)
**Build:** 59

### Codex Browser
- New tabbed browser for Objects, Pickups, and NPCs scraped from wiki.gg.
- 3 JSON data files + 90 images downloaded and integrated.
- Detail view with wiki descriptions, accessible from main menu button.

### Special Gun/Item Dashboards
- Shellegun: 3-mode switcher (Pistol Manual / Auto / Beam) with DPS display.
- Chamber Gun: 10-floor selector (Keep through Bullet Hell) with floor-specific stats.
- Platinum Bullets: Stacking kill counter (0-999) with DPS scaling display.
- Iron Coin: 3-use tracker with remaining count and reset button.
- Casey and Kill the Past tracker also added.
- All dashboards persist state via SharedPreferences and integrate with DamageCalculator.
- Dashboards wrapped as SliverToBoxAdapter for proper scrolling in CustomScrollView.

### Tactical Stats Grid Refactor
- PeriodicTile tacticalStats mode refactored from Stack/Positioned to clean 2x3 grid.
- Rank/quality badges no longer overlap — dedicated header row + stat grid + footer.
- Bigger fonts (12-14px stats), clearer labels, no more squished elements.
- Removed unused `_buildGridStat` and `_buildMiniStat` methods.

### Run Event Log System
- New logging system with category colors (combat, pickup, shrine, transfer, etc.).
- Legend panel for at-a-glance category reference.
- Synergy detection logging — active synergies flagged on acquisition.
- Transfer logging with player names in multiplayer mode.
- Curse/coolness tracking integrated into event stream.

### Character Select Polish
- Scale animation on card tap, gradient overlay on selected character.
- Loadout badges showing gun/item counts, border accents per character.
- Haptic feedback on selection.

### MP Session Names
- Replaced generic animal names with 30+ Gungeon bosses, NPCs, and enemies.
- Names now thematically consistent with Enter the Gungeon universe.

### UI Polish
- Quick action cards: category-colored with deduplicated hint text.
- Capsule polish: removed redundant icons, enlarged stat values (14→16) and labels (8→9.5).
- Preserved COOL/CURSE neon glow on value text.

### Dead Code Removal
- Removed `neckbearApproved` field from Gun and Item models + JSON serialization.
- Deleted `BugReporter` utility and `NeckbearMedal` widget entirely.
- Cleaned all imports and references across 6 files.

### Bughunt
- `flutter analyze`: 0 errors, all warnings pre-existing (16 in active_run_screen, 3 in periodic_tile).
- All controllers properly disposed (PageController, AnimationController).
- All async overlay calls guarded with `context.mounted`.
- RunProvider methods verified: clamping, persistence, notifyListeners on all new setters.

---

## v1.4.0 — Code Cleanup + MP Summary Fixes (July 21, 2026)
**Build:** 58

### MP Summary Fixes
- Active synergy counts now show per-player (P1/P2) instead of shared total.
- Coolness/Curse rows consolidated to single centered display (was duplicated per-player).
- Super Serum partial-synergy hint filters out already-owned items.
- `_MpSummaryPage` converted to `StatelessWidget` (no state needed).

### UI Fixes
- Summary tab label no longer truncates on narrow phone screens (FittedBox replaces Flexible+ellipsis).

### Code Cleanup
- Deleted `_ThemeLauncherTile` (97 lines, unused) from `settings_sheet.dart`.
- Deleted `_ElementRow` (63 lines, unused) from `gungeoneer_header.dart`.
- Fixed 2x `.withOpacity()` → `.withValues(alpha:)` in `gungeoneer_header.dart`.
- `flutter analyze`: 0 new issues.

---

## v1.3.0 — Wiki Data Enrichment: 100% Ammonomicon Coverage (July 21, 2026)
**Build:** 57

### Ammonomicon Entries — Full Coverage
- **Guns**: All 239 guns now have `ammonomicon_entry` (was 0/239). Scraped from enterthegungeon.wiki.gg infobox `.druid-row-desc` via Playwright browser automation.
- **Items**: All 270 items now have `ammonomicon_entry` (was 0/270). 163 from wiki infoboxes, 107 from `effect` field fallback where wiki had no infobox.

### Data Fixes
- 56 gun `spread` values corrected to include degree symbol (`°`).
- C/B/A/S rank gun `quote` and `spread` repairs from wiki data.
- 4 broken synergy references fixed: `IBomb Companion App` → `iBomb Companion App`, `Master Round` → `Master Round I-V`, `Ser Junkan` → `Ser Junkan 1`.
- 2 missing synergy items added: Wood Beam → Pea Cannon, Grasschopper → To Serve Android.

### Validation
- 395/395 synergies cross-validated against wiki master Synergies table (391 perfect match, 4 intentional name corrections).
- 0 structural errors, 0 broken back-references, 0 duplicate names.
- `flutter analyze`: 0 errors on all screens.

---

## v1.2.0 — MP Summary Page + Animated Gungeoneer GIFs (July 21, 2026)
**Build:** 56

### New Feature: Multiplayer Summary Page
- Third tab in the MP `PageView` (P1 → P2 → Summary), accessible by swiping right or tapping the Summary tab in the MP header.
- Shows both gungeoneers side-by-side as animated in-game GIFs with neon-accented portrait frames (cyan for P1, purple for P2).
- Displays each player's nickname below their portrait, plus character name.
- Stats comparison panel: guns count, items count, active synergies, max DPS, damage bonus %, coolness, curse — all in a clean P1 | STAT | P2 layout.
- Synergy Overview panel: lists all possible synergies from the combined inventories with ACTIVE/PARTIAL/LOCKED status indicators and missing item hints for partial synergies.

### New Assets: Animated Gungeoneer GIFs
- 9 in-game animated GIFs added to `assets/images/gungeoneers/`: the_marine, the_pilot, the_convict, the_hunter, the_bullet, the_robot, the_cultist, the_paradox, the_gunslinger.
- New `gungeoneerGifPath()` helper in `asset_paths.dart` for resolving GIF paths by character name.

### Damage Calculator Assessment
- Comprehensive assessment written to `docs/damage_calculator_assessment.md` identifying 7 issues and a 5-phase redesign plan.

---

## v1.1.0 — Universal Damage Calculator + UI Contrast Overhaul (July 7, 2026)
**File:** `gungeon-mate-v1.1.0.apk`
**Build:** 54

### New Feature: Universal Damage Calculator
- New `lib/services/damage_calculator.dart`: scans a player's equipped guns + items via `EffectTagger.scan()` for `damage_up`/`damage_down` tags, extracts quantifiable percentages, and produces a single aggregate multiplier.
- New `_UniversalDamageCalculatorSliver` in `active_run_screen.dart`: shown on every character's dashboard except Robot (which keeps its dedicated junk/lies HUD), rendering a collapsible terminal listing each contributing source plus a per-gun DPS table with the multiplier applied.
- New `showDamageCalculator` toggle added to `VisualPrefs` (`app_theme.dart`), persisted, default on. Exposed as a switch in Settings → Run Utilities → "🧮 DASHBOARD DISPLAY".

### UI Contrast Overhaul
- **Root Cause:** Several dashboard/settings panels used near-invisible background alpha (2–8% white/card tint) that blended into custom wallpapers, making text hard to read.
- `gungeoneer_header.dart`: stat capsule chips (Coolness/Curse/CD/Ammo/Synergies/DPS) now use a solid dark backing (28% black / 16% tint when active) instead of 2–8% alpha.
- `settings_screen.dart`: boosted background opacity on the wallpaper mode picker, still-wallpaper picker, font picker, typography card, inventory grid card, and all Run Utilities panels (Multiplayer, Language, Damage Calculator, util tiles) from ~3–5% to 45–95% opacity.
- `periodic_tile.dart`: removed the 12%-opacity full-bleed "ghost" icon background on `tacticalStats` mode cards (it fought with the stat readout and looked muddy against busy wallpapers). Cards now use a solid dark backing plus a crisp 20px icon next to the item/gun name in the title banner.

## v1.0.1 — Bug Fixes: BG, Wallpaper & Particle Cleanup, MP Reconnect (July 7, 2026)
**File:** `gungeon-mate-v1.0.1.apk`
**Build:** 53

### Bug Fixes
- **Background Disappears on Tap:** Fixed stale `ThemeOverlay.currentScreenIndex` mutation in `HomeScreen.build()` — deferred to post-frame callback to prevent the animated background from vanishing when tapping after starting a new run.
- **Wobbling Sewer Jelly Wallpaper Removed:** Removed the problematic animated wallpaper entry from `kAnimatedWallpapers`; added migration guard so users who had it selected are auto-switched to a safe fallback.
- **Particle Systems Cleaned Up:** Removed wind, gunpowder, and bullet particle types from the `ParticleType` enum and rendering code in `theme_overlay.dart`. Persisted particle indices are auto-migrated to avoid crashes.
- **Multiplayer Auto-Save & Reconnect:** Added periodic session save every 20s during MP sessions, immediate `saveCurrentSession()` on disconnect/drop detection, and unlimited auto-reconnect retries with exponential backoff instead of entering a terminal error state on transient failures.
- **Version Labels Fixed:** Corrected stale version labels (`v0.9.994` and `v2.3.0`) on the home screen and changelog dialog to show the correct version.

## v1.0.0 — Neckbear's Approval for Items + Scraper Fixes (July 6, 2026)
**File:** `gungeon-mate-v1.0.0.apk`
**Build:** 52

### Neckbear's Approval Extended to Items
- Added `neckbearApproved` bool field to the `Item` model (`neckbear_approved` in items.json), wired to `NeckbearMedal` on the Browse list row and Item Detail header, mirroring the gun implementation from v0.9.998.
- New `scripts/neckbear_check_items.py` and `scripts/fix_xtg_contamination_items.py` audit/repair tooling, mirroring the gun-side scripts.

### Legacy Wiki Page Support (Root Cause)
- **Root Cause** — `scripts/enrich_from_wikigg.py`'s `parse_item()` only understood the current `druid-infobox` wiki.gg layout. ~140 items still use the older `infoboxtable` layout, so every field for those pages silently came back empty ("NO CACHE").
- **Fix** — Added `extract_legacy_fields()`, a fallback regex-table parser for the legacy layout, wired in via `setdefault` so it never overrides a druid-infobox match.

### Parenthetical Disambiguation Lookup Fix
- **Root Cause** — Items named like `C4 (Item)` were fetched/cached under the literal name including the parenthetical suffix, which doesn't exist on the wiki, so they always reported as missing.
- **Fix** — `base_name()` (in the enrich, check, and fix-contamination scripts) now also strips a trailing `(...)` suffix in addition to roman numerals before cache lookup.

### N/A Sell Price Detection (Root Cause)
- **Root Cause** — The wiki renders unsellable items' Sell Price row as an image (`alt="N/A"`) instead of plain text. `extract_sell_price()` only searched the stripped text value, so it always returned empty for these rows — affecting both current and legacy layouts.
- **Fix** — Both `extract_sell_price()` (druid) and `extract_legacy_fields()` (legacy) now check the raw row HTML for `alt="N/A"` first. Corrected sell_price for: Busted Television, Coolant Leak, Disarming Personality, Enraging Photo, Galactic Medal of Valor, Military Training, Number 2, Prime Primer, Ring of Miserly Protection, Sponge, Trusty Lockpicks.

### Data Cleanup
- Cleared bogus `"N damage"` text that had contaminated several items' `recharge_time` fields (should be empty for damage-triggered actives, handled by existing UI fallback logic).
- Cleared a literal `"None"` string that had been scraped into Busted Television's `recharge_time` (should be empty, not the word "None").
- Fixed specific mismatches found during audit: `C4 (Item)` chest_color, `Ser Junkan 1` sell_price, and earlier session fixes for Spice, Boomerang, Orange, Ticket, Box, Drill sell_price/type fields.

### Full Re-Verification
All 270 items re-audited after the fixes. 268/270 confirmed clean automatically. Remaining 2 (Drill, Duct Tape) are non-issues — the wiki lists "Floor"/"Single Use" as their recharge condition (non-numeric special text), and our existing json values already correctly describe them; the scraper intentionally declines to overwrite recognizable special-case text.

---

## v0.9.999 — Root-Cause Fix: Exit the Gungeon Data Contamination (July 6, 2026)
**File:** `gungeon-mate-v0.9.999.apk`
**Build:** 51

### Wiki Scraper Root Cause Fix
- **Root Cause** — `scripts/enrich_from_wikigg.py`'s `extract_druid_row_value()` blindly stripped HTML tags from a stat row without accounting for wiki.gg's `druid-toggleable-data` tab widget. When a stat had multiple tabs (e.g. Enter the Gungeon vs Exit the Gungeon, or "XTG"/"HoTG" variants), both tab values got concatenated into a single string (e.g. `"40 20"`, `"Semiautomatic Automatic"`).
- **First-pass fix (too broad)** — Initially stripped *any* non-`"ETG"`-keyed toggle tab. This incorrectly nuked legitimate in-game state toggles that reuse the same widget for non-version purposes (AC-15's `Armored`/`Unarmored` stats — both valid ETG data).
- **Corrected fix** — Only strip non-ETG toggle tabs when the row *also contains* a literal `data-druid-tab-key="ETG"` tab (confirming it's actually a game-version row). Rows using other toggle purposes (Armored/Unarmored, per-stage evolution, etc.) are left completely untouched.
- **Tooling added** — `scripts/neckbear_check.py` (diff every gun against cached wiki, auto-stamp `neckbear_approved`) and `scripts/fix_xtg_contamination.py` (safe prefix-match repair: only overwrites a field when `json_value == wiki_value + " " + garbage`, so legitimate formatting differences like Heroine's charge-level labels are never touched).

### 22 Guns Repaired (78 fields)
A.W.P., AK-47, Alien Sidearm, Anvillain, Balloon Gun, Bee Hive, Big Iron, Big Shotgun, Blasphemy, Blunderbuss, Brick Breaker, Cold 45, Grenade Launcher, H4mmer, Jolter, Pitchfork, Regular Shotgun, Void Core Assault Rifle — damage, fire_rate, magazine_size, ammo_capacity, reload_time, shot_speed, range, force, spread, and type fields cleaned of Exit the Gungeon contamination.

### Full Re-Verification
All 239 guns re-audited post-fix. 235/239 clean automatically. Remaining 4: 3 are wiki "∞ Infinity" range symbols (image-only, no text to compare — our numeric placeholder values are an intentional prior design choice), 1 is Heroine's already-correct charge-level label formatting.

---

## v0.9.998 — Neckbear's Approval + Cat Gone + BG Fix (July 6, 2026)
**File:** `gungeon-mate-v0.9.998.apk`
**Build:** 50

### Cat Throne Overlay Removed
- Deleted the `_SecretCatThroneOverlay` call site in `theme_overlay.dart`. No more surprise screen-peek widget.

### Broken Still Wallpapers Fixed
- **Root Cause** — `kStillWallpapers` in `app_theme.dart` listed 28 PNG entries; `assets/images/wallpapers/still/` was completely empty on disk. Every "Still Wallpaper" selection rendered nothing.
- **Fix** — Emptied `kStillWallpapers`. `WallpaperMode.customStill` is now filtered out of the settings picker while the list is empty, so users can't select a broken mode.

### Neckbear's Approval Medal
- Added `neckbearApproved` bool field to the `Gun` model (`neckbear_approved` in guns.json).
- New `NeckbearMedal` widget (`lib/widgets/neckbear_medal.dart`) — a cute 🐻 badge shown next to the gun name on both the Browse list row and the Gun Detail header when verified.
- Wrote `scripts/neckbear_check.py`: diffs every gun in guns.json against its cached wiki.gg infobox (reusing `enrich_from_wikigg.py` parsers), auto-stamping `neckbear_approved: true` on exact matches.
- **Result: all 239 guns checked, all 239 approved.** 3 flagged mismatches (Big Iron, Budget Revolver, Heroine) were manually confirmed as wiki HTML toggle-tab parsing artifacts (ETG + Exit the Gungeon values concatenated) — json values were already correct per prior v0.9.991 fixes.

---

## v0.9.997 — Cat Throne White Screen: Root Cause Found (July 5, 2026)
**File:** `gungeon-mate-v0.9.997.apk`
**Build:** 49

### Cat Bullet King Throne White Overlay Fix
- **Root Cause** — The secret `_CuriousCatStareWidget` in `ThemeOverlay` used a `Positioned` widget directly inside `AnimatedBuilder` (not a `Stack`). Since `Positioned` must be a direct child of `Stack`, its `width`/`height` constraints were ignored and the cat image was stretched to fill the entire screen as a semi-transparent white overlay whenever "Cat Bullet King Throne" was in the inventory.
- **Fix** — Wrapped the `Positioned` in a `Stack` so constraints apply correctly. The cat now peeks from the bottom-right corner as intended.

---

## v0.9.996 — White Screen Fix: Scaffold Transparency (July 5, 2026)
**File:** `gungeon-mate-v0.9.996.apk`
**Build:** 48

### White Opaque Screen Fix
- **Root Cause** — `scaffoldBackgroundColor` in `AppTheme.themeFor()` was 90% opaque when `hypnoticBgEnabled` was false. This obscured ThemeOverlay backgrounds (wallpapers, particles, galaxy) on any screen without explicit transparent Scaffold.
- **Fix** — Now always `Colors.transparent`. ThemeOverlay provides the base solid color via its own `Container(color: f.scaffold)` layer.

### Full Screen Audit
- **10+ Screens Fixed** — Multiplayer Lobby, Multiplayer Connect, Synergies Overview, Stats Detail, Shrine Picker, Item Detail, Favourites, Effects Summary, Character Select, and HomeScreen loading/error states now explicitly set `backgroundColor: Colors.transparent` on both Scaffold and AppBar.

---

## v0.9.995 — Visual Polish: Parallax, Overlay, Wind Artifacts, Theme BG (July 5, 2026)
**File:** `gungeon-mate-v0.9.995.apk`
**Build:** 47

### Smooth Parallax
- **60fps Interpolation** — Still wallpaper background converted to StatefulWidget with AnimationController for exponential lerp of gyroscope tilt. No more sensor jitter or low FPS.

### Quick Add Overlay Fix
- **Race Condition Resolved** — Fixed bright white overlay when quick-adding items. Uses FocusManager unfocus + PostFrameCallback to sequence modal dismissal before navigation.

### Wind Path Artifacts Removed
- **Clean Particle Backdrops** — Eliminated wobbly "wind current" bezier curves from Gold Dust, Hellfire, Cosmic Rift, and Custom Particle painters. No more ghostly lines drifting upward.

### Lingering Background Fix
- **Theme Picker Transparency** — ThemePickerScreen Scaffold was 90% opaque, hiding ThemeOverlay backgrounds during preview and causing a flash on pop. Now transparent like all other screens.

---

## v0.9.994 — Robot Terminal + Theme Overhaul + 10 New Themes (July 5, 2026)
**File:** `gungeon-mate-v0.9.994.apk`
**Build:** 46

### Robot Dashboard
- **Junk Toggles** — Fixed font overflow. Gold Junk and Lies toggles are now bigger, more compact tap targets with icon + label + subtitle layout.
- **DMG Boost Badge** — Now larger and more prominent with border styling.
- **Damage Calculator Terminal** — New expandable retro green terminal showing per-gun damage calculations (weapon name, base DPS, robot-boosted DPS, delta) with monospace styling and total DPS summary.

### Theme Picker Redesign
- **Chips Removed** — Removed chip rows from theme preview cards per user request.
- **Per-Theme Preview Data** — All 21 themes now have custom stats, bullet notes, and subheadings with real Gungeon flavor.
- **Weighted Palette Bar** — Replaced individual color boxes with a continuous weighted palette swatch bar showing BG/CRD/PRI/SEC/ACC with actual hex colors as fill and luminance-aware text overlay.

### 10 New Themes
- **Gungeon Proper** — Castle stone blue, royal purple, dungeon iron gray
- **The Oubliette** — Sludge green, corroded bronze, toxic lime
- **Past Paradox** — Cosmic nebula black, neon cyan, void violet
- **High Priest Void** — Void cultist purple, candle yellow, shadow magenta
- **Robot's Core** — Circuit teal, battery green, matte steel gray
- **Cult of Gundead** — Soft brass gold, lead gray, target red
- **Synergy Surge** — Synergy arrow teal, chest blue, electric white
- **Glitched Chest** — Terminal black, artifact magenta, digital distortion green
- **Lich's Tomb** — Bone white, eerie phantom teal, crypt charcoal
- **Winchester's Game** — Fairground green, prize ticket orange, carnival wood brown

---

## v0.9.992 — Unicorn Theme Family + HUD & Effect Fixes (July 5, 2026)
**File:** `gungeon-mate-v0.9.992.apk`
**Build:** 45

### Bug Fixes
- **Special Gun Panels** — Fixed substring matching bug where Ser Junkan, Gunderfury, and Triple Gun dashboards appeared for characters who don't possess those items. Now uses exact name matching.
- **Status Effects Rendering** — Replaced all 45+ "Status Effects" lore ref tokens across items.json and guns.json with context-specific effect words (fire, poison, frozen, stun, stealth, charm, etc.). Effects now display correctly instead of showing a generic italic "Status Effects" link.

### Theme Updates
- **Unicorn Bubblegum** — Removed twinkling star sparkle particles. Ambient pink/teal glow remains.
- **Unicorn II (Neon)** — New theme: neon-charged cotton candy with hot pink, electric teal, and bright orchid. Stronger glow intensity.
- **Unicorn III (Dream)** — New theme: softer whispered cotton candy with blush pink, sage teal, and dusty lavender. Rounded 20px corners and gentle glow.
- **Unicorn IV (Sunset)** — New theme: cotton candy at golden hour with coral pink, warm peach, and golden teal.

### Planning
- **MP Auto-Reconnect** — Created implementation plan for automated multiplayer save/reconnect system at `docs/mp_auto_reconnect_plan.md`.

---

## v0.9.991 — Data Corrections & Devolver HUD Fix (July 4, 2026)
**File:** `gungeon-mate-v0.9.991.apk`
**Build:** 44

### Data Corrections
- **Monster Blood** — Fixed first wiki note to include Robot's 5-10 coin drop range.
- **Grappling Hook** — Replaced 'Status Effects' reference with inline 'stuns' text for clarity.
- **Budget Revolver** — Removed incorrect Exit the Gungeon dual stats; now shows only EtG values.
- **Big Iron** — Fixed range from '16 15' to correct value of 16.
- **Heroine** — Fixed DPS and damage fields to properly label all three charge levels (Level 1/2/3).
- **M16** — DPS now includes Machine Gun, Grenade Launcher, and Combined DPS values.

### UI/UX Fix
- **Devolver HUD** — Fixed substring matching bug where 'Devolver' triggered the Evolver HUD dashboard due to `contains('evolver')` matching. Now uses exact name match.

---

## v0.9.99 — Particle System Overhaul, FPS Fix, Parallax Rework & Glassmorphic Settings (June 30, 2026)
**File:** `gungeon-mate-v0.9.99.apk`
**Build:** 43

### Glassmorphic Settings Panels
- **Unified Glass Aesthetic** — All settings screen panels (Typography, Inventory Grid, Particle Tuning, Switch Rows) and settings sheet dropdown/rows now use `flair.card` at 35-38% alpha with themed primary borders. Panels show the background through them subtly while remaining fully readable.

### Elemental Particle Types
- **7 New Types** — Fire (embers & sparks), Water (bubbles & droplets), Earth (dust & stone pebbles), Air (wind gusts & streaks), Bullets (golden shells & brass casings), Gunpowder (smoke puffs & muzzle flash sparks), Stars (cosmic sparkles with white cores).
- **Removed Old Types** — All emoji-based particles (necromantic skulls, skeletal bones, tombstone crosses, rainbow prismatic, frost, toxic, lightning, gold/brass/steel) replaced with pure Canvas vector shapes for maximum FPS.

### Massive FPS Optimization
- **Zero MaskFilter.blur** — Removed all expensive blur calls from every particle painter (curse fog, sparkles, hellfire, gold dust wind, cosmic rift wind).
- **RadialGradient Shaders** — Replaced curse fog's blur(45) with cheap RadialGradient shaders for the same visual effect at fraction of the GPU cost.
- **Concentric Circle Glows** — Replaced sparkle blur halos with cheap concentric alpha-gradient circles.
- **RepaintBoundary** — Added to custom particle backdrop to isolate repaints.
- **Memory Savings** — Removed Gun_Fairy.webp async asset load that was wasting memory on every screen.

### Particle Cutoff Fix
- **Off-Screen Travel** — Removed all modulo wrapping from particle positions across all 10+ backdrop painters. Particles now travel fully off-screen before fading out instead of wrapping around abruptly.

### Parallax Rework for Large Screens
- **Wider Tilt Range** — Increased accelerometer clamp from ±6 to ±10 and smoothing from 0.12 to 0.18 for more responsive gyroscope parallax.
- **Screen-Scaled Movement** — Still wallpaper parallax now scales by screen dimensions instead of fixed 3.8px, so bigger phones get proportional movement.
- **Lower Filter Quality** — Reduced image filter quality to low for better FPS on wallpaper rendering.

---

## v0.9.98 — Unicorn Bubblegum Rework & Particle Count Control (June 30, 2026)
**File:** `gungeon-mate-v0.9.98.apk`
**Build:** 42

### Unicorn Bubblegum Theme Visual Rework
- **6-Color Pastel Palette** — Sparkle particles now cycle through hot pink, lavender, mint cyan, soft pink, amethyst, and pure white for a vibrant cotton-candy aesthetic.
- **Dual-Layer Glow Halos** — Each particle gets an outer bloom (6px blur) and mid glow (2.5px blur) using `MaskFilter` for a premium magical bloom effect.
- **Three Shape Varieties** — Particles alternate between 4-pointed sparkle stars, glowing bubbles with white cores, and 6-pointed double-stars with layered rotation.
- **Bright White Cores** — All sparkle shapes now feature crisp white center dots for extra twinkle punch.

### Particle Count Now Affects All Theme-Default Backdrops
- **Universal Count Control** — The user-controlled particle count slider (5–120) now drives all 9 theme-default backdrop widgets: GoldDust, Sparkles, BrassMotes, IceCrystals, WhiteDust, ToxicBubbles, ForgeEmbers, Hellfire, and CosmicRift.
- **Live Regeneration** — Added `didUpdateWidget` to every backdrop widget so particle specs regenerate immediately when the density slider changes — no app restart required.
- **Clearer Tooltip** — Updated the settings tooltip to clarify the slider affects both theme-default and custom particle types.

---

## v0.9.97 — Retro Glitch Cinematic Breach & Wallpaper Update (June 23, 2026)
**File:** `gungeon-mate-v0.9.97.apk`
**Build:** 41

### Dynamic 3D Retro Glitch Cinematic
- **Interactive 3D Corridor** — Developed a cinematic intro page with responsive Tailwind CSS, realistic camera forward POV corridor runs, and screen slamming transitions.
- **Web Audio Sound Synthesis** — Synthesizes authentic retro glitch laser effects, heavy bass impacts, and screen clicks directly in the browser.
- **Physical Particle Explosion** — Programmed a high-performance physical particle blast on canvas that triggers on screen slam, throwing dithered, outline-glowing block particles directly at the viewport with active bounce.
- **GungeonMate Live Replica** — Rendered a stunning, high-fidelity dark-neon interactive mockup of GungeonMate's actual home layout with active space galaxy.

### 9 New High-Fidelity Still Wallpapers
- **Expanded Wallpaper Gallery** — Integrated and registered 9 new beautifully rendered, high-contrast, dithered Gungeon-lore still wallpapers (Cyber Glitch, Circuit Wireframe, Glitch Bullet Tracks, CRT Corridor, Unicorn Rainbow Blaster, Archival Golden Keep, Frozen Tomb Crypt, Forge Volcanic Magma, Cursed Ritual Chamber).

---

## v0.9.8 — Great UI Condensation & Galaxy Home Screen (June 19, 2026)
**File:** `gungeon-mate-v0.9.8.apk`
**Build:** 40

### Simplified Particle Settings
- **Clean Particle Options** — Stripped particle settings down to just Type and Density. Completely removed custom sizing, emitters, rotation, gravity vortex, flicker, subtle mode, and touch sparkles for perfect, pre-tuned handcrafted excellence.

### Swipe-to-Select Pickers
- **Wallpaper Mode Picker** — Replaced dropdown with a horizontal swipe picker showing icons and labels for Theme Default, Custom Still, and Custom Animated.
- **Still & Animated Wallpaper Pickers** — Swipe through available wallpapers with live name display and animated scaling.
- **Font Family Picker** — Swipe through all 60+ fonts with a live preview showing the font name and a sample Gungeon phrase in the actual font styling.

### Settings Reorganization
- **Wallpaper Section Moved Up** — Relocated the Wallpaper & Parallax Engine Lab above particles and typography for faster access.
- **Condensed Layout** — Removed redundant sections and consolidated the menu for a cleaner, more focused experience.

### Galaxy Always on Home with Particles
- **Home Screen Galaxy** — The swirling Galaxy animated background plays on the Main Menu Home screen, creating an immersive cosmic atmosphere.
- **Particles in Front of BG** — Premium background particles now drift gracefully in front of the Galaxy background and all active custom wallpapers.
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
