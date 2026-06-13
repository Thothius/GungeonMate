# Gungeon Mate

<p align="center">
  <img src="assets/icon/icon.png" width="128" height="128" alt="Gungeon Mate Icon">
</p>

<p align="center">
  <b>The definitive companion app for Enter the Gungeon.</b><br>
  Track runs, master guns & items, unlock synergies, chat with NPCs, and chase high scores — all offline, zero accounts.
</p>

<p align="center">
  <img alt="Version" src="https://img.shields.io/badge/version-1.8.4-00D2FF?style=flat-square">
  <img alt="Platform" src="https://img.shields.io/badge/platform-Android%20%7C%20Windows%20%7C%20Linux-6C5CE7?style=flat-square">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-00B894?style=flat-square">
</p>

---

## Features

### Core Run Tracking
- **Pick a Gungeoneer** — auto-loads starting loadout, health, and passives.
- **Live Inventory Grid** — compact, auto-scaling tiles from 3 to 20+ items. Tap any tile for instant detail.
- **Auto-computed Coolness & Curse** — dynamically calculated from your inventory, with manual shrine adjustments.
- **Persistent Runs** — auto-saved to `SharedPreferences` on every change. Kill the app, reboot your phone — your run survives.

### Item Database
- **239 Guns & 270 Items** — fully offline, filterable by quality tier (S / A / B / C / D).
- **Rich Detail Views** — stats, effects, synergies, wiki links, and one-tap remove from run.
- **Favorites System** — bookmark your go-to guns and passives for quick access.
- **Synergy Engine** — browse all 395 synergies grouped by item. Instantly see which are active vs. which items you still need.

### NPC Dialogue System
- **Interactive NPC Conversations** — talk to Bello, Winchester, The Vampire, and more.
- **Chamber-Aware Dialogue** — NPCs react differently based on which Gungeon floor you're on.
- **Secret Quests** — 5 hidden delivery storylines for Flynt, Vampire, Sell Creep, Professor Goopton, and Cursula.
- **Bello's Secret Cabinet** — deliver rare Gungeon Anomalies to unlock a permanent 30% shop discount.
- **Cursula Flirting Engine** — playful, personality-matched dialogue lines.
- **Typewriter Animation** — adjustable speed (Instant, Fast, Normal, Slow) with haptic ticks.

### Winchester Minigame
- **10-Level Campaign** — chamber-based progression with increasing difficulty.
- **Dual-Thumb Controls** — BAM! fire button + PlayStation-style analog aim.
- **Dog Treat Cookie Throw** — throw treats to guide your dog companion through levels.
- **Baby Good Mimic Synergy** — co-op purple-tinted twin companion dog with independent AI roaming.

### Visual Customization
- **Trippy Backgrounds** — hypnotic animated backdrops (Edge Drip, Glint Sheen, Elastic Wobble) rendered behind all UI layers.
- **Dark Neon Aesthetic** — deep space grey-purple containers with bright loot-tier color accents (Amber, Cyan, Green, Pink, Purple).
- **Interactive Main Menu Mascot** — tap the mascot for randomized Gungeon-themed speech bubbles.
- **Custom Dice Skins** — Classic, Gold, Frost, Molten, Void, and Toxic skins for the Gunfortuna die roller.

### Multiplayer
- **Local Co-op Sync** — Bluetooth / Wi-Fi Direct event-driven state sync for dual-player runs via Google Nearby Connections.
- **Inventory Transfer** — send your entire run state to a friend's device seamlessly.

### Quality-of-Life
- **Haptic Feedback** — tactile taps on buttons, dice rolls, and dialogue advances.
- **In-App Changelog** — dynamic version history loaded from JSON, accessible from the main menu.
- **Wiki.gg Integration** — in-app webview and external links pointing to `enterthegungeon.wiki.gg`.
- **Crossbow Breakpoint Calculator** — Huntress-specific damage breakpoint analysis.
- **Dog Interaction Counters** — persistent pet and treat counters for your companion.

---

## Screenshots

| Main Menu | Active Run | Item Detail |
|-----------|-----------|-------------|
| *(screenshot placeholder)* | *(screenshot placeholder)* | *(screenshot placeholder)* |

| NPC Dialogue | Winchester Minigame | Synergies |
|--------------|---------------------|-----------|
| *(screenshot placeholder)* | *(screenshot placeholder)* | *(screenshot placeholder)* |

---

## Build Instructions

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.7+ with `flutter` in your PATH
- Android Studio or Visual Studio (for Windows desktop builds)

### Run in Debug Mode

```bash
cd gungeon_mate
flutter pub get
flutter run
```

### Android Release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Windows Desktop

```bash
flutter build windows --release
# Output: build/windows/x64/runner/Release/
```

---

## Project Structure

```
gungeon_mate/
├── lib/
│   ├── main.dart
│   ├── models/              # Gun, Item, Synergy, Shrine, Gungeoneer, NPCDialogue, RunState
│   ├── providers/           # RunProvider (state + SharedPreferences persistence)
│   ├── screens/             # MainMenu, ActiveRun, ItemDetail, NPCView, Browse, Settings, WinchesterMinigame
│   ├── services/            # AppTheme, Haptics, Multiplayer transport
│   └── widgets/             # QualityBadge, AnimatedChatBubble, ThemeEngines, GungeoneerHeader
├── assets/
│   ├── data/                # JSON databases (guns, items, synergies, shrines, NPCs, changelog)
│   └── images/              # Sprites, NPC portraits, dice skins
├── android/                 # Android platform configuration
├── windows/                 # Windows desktop configuration
├── linux/                   # Linux desktop configuration
├── macos/                   # macOS desktop configuration
├── ios/                     # iOS platform configuration
├── test/                    # Unit & widget tests
├── pubspec.yaml             # Dependencies & asset declarations
└── analysis_options.yaml    # Dart linting rules
```

---

## Data Sources

All item stats, descriptions, and synergy data are sourced from the official **Enter the Gungeon Wiki** at [wiki.gg](https://enterthegungeon.wiki.gg). The app ships with a bundled JSON snapshot — no live internet required for core functionality.

---

## Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | Lightweight state management |
| `shared_preferences` | Persistent local storage |
| `nearby_connections` | Bluetooth / Wi-Fi Direct multiplayer sync |
| `permission_handler` | Runtime BT/location permission prompts |
| `url_launcher` | External wiki links |
| `webview_flutter` | In-app wiki browser |
| `flutter_animate` | Declarative animations |
| `google_fonts` | Typography |
| `intl` | Internationalization utilities |

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  <i>Made with love for the Gungeon community.</i><br>
  <b>v1.8.4</b> — "The Lore & Dialogue Update"
</p>
