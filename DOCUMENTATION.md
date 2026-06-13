# Gungeon Mate - Documentation

**Version:** 0.9.6  
**Description:** Companion app for Enter the Gungeon - track your run, guns, items, synergies, and shrines. Fully offline, no account, no cloud.

---

## Overview

Gungeon Mate is a Flutter app designed to help players track their Enter the Gungeon runs. It provides inventory management, synergy tracking, shrine activation logging, and real-time multiplayer co-op tracking via Bluetooth.

### Key Features

- **Active Run tracking**: Pick a Gungeoneer, auto-loads starting loadout
- **Inventory grid**: Compact tiles that scale from 3 to 20+ items
- **Tap any item** → Full detail view (stats / effect / synergies / remove button)
- **Auto-computed Coolness & Curse** from items, with manual adjust for shrines
- **All Synergies overview**: Every currently possible synergy grouped by item, shows which are active vs what's still missing
- **Browse** all 239 guns & 270 items, filter by quality
- **Shrines reference** (8 shrines) with auto-detected curse/coolness deltas
- **Multiplayer co-op**: Real-time inventory sync between two devices via Bluetooth
- **Persistent**: Active run auto-saves to SharedPreferences on every change

---

## Getting Started

### Prerequisites

- Flutter 3.7+
- Android device or emulator
- For multiplayer: Two Android devices with Bluetooth

### Running the App

```bash
cd gungeon_mate
flutter pub get
flutter run
```

### Building APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Core Features

### 1. Character Selection & Run Management

**Screens:** `MainMenuScreen`, `CharacterSelectScreen`

- Choose from 9 Gungeoneers (The Marine, The Hunter, The Pilot, The Convict, The Cultist, The Robot, The Bullet, The Gunslinger, The Paradox)
- Each character auto-loads their starting guns and items
- Run state persists across app restarts
- End run button clears current run

### 2. Inventory Management

**Screen:** `ActiveRunScreen`

**Features:**
- Grid view of guns and items with quality-colored tiles (S=red, A=orange, B=blue, C=green, D=gray)
- Tap any item to view full details
- Remove items from inventory
- Sort guns by DPS, quality, or name
- Toggle between grid and list views
- Quality badges on all items

**Data:**
- 239 guns with stats (damage, fire rate, clip size, reload time, range, DPS)
- 270 items with effects, quality ratings
- 395 synergies

### 3. Synergies Tracking

**Screen:** `SynergiesOverviewScreen`

**Features:**
- View all synergies for items you currently own
- See which synergies are active vs missing
- Grouped by item for easy navigation
- "any_of" alternatives highlighted when owned
- Tap synergy to view full effect description

### 4. Shrine Activation

**Screen:** `ShrinePickerScreen`

**Features:**
- 8 shrines with curse/coolness deltas
- Special handling for complex shrines (Cleanse, Hero, etc.)
- Manual reminders for player-only actions (lose heart container, pick up companion, etc.)
- Auto-applies curse/coolness deltas
- Tracks shrine usage in run summary
- Undo capability

### 5. Browse & Search

**Screen:** `BrowseScreen`

**Features:**
- Search guns and items by name
- Filter by quality tier (S, A, B, C, D)
- Add items directly to inventory
- View detailed stats and effects
- Rich text rendering for item descriptions
- Linkable item references (tap to navigate)

### 6. Favourites

**Screen:** `FavouritesScreen`

**Features:**
- Star guns and items for quick access
- Persists across runs
- Sorted alphabetically
- Quick add to inventory from favourites

### 7. Multiplayer Co-op

**Screens:** `MultiplayerLobbyScreen`, `MultiplayerScreen`

**Architecture:**
- Uses Google Nearby Connections (Bluetooth + WiFi Direct)
- P2P point-to-point strategy for best latency
- Automatic snapshot sync every 200ms on inventory changes
- Heartbeat every 5 seconds with 30s watchdog timeout
- Protocol versioning for compatibility

**Roles:**
- **Main Player**: Advertises as host, plays any character
- **Sidekick**: Discovers host, forced to play The Cultist

**Features:**
- Real-time inventory sync between devices
- Gift system: Send guns/items to peer
- Request system: Ask peer for items with accept/deny
- Role-aware page labels ("You (Main)" / "Peer (Cultist)")
- Connection status indicator (green/orange/red)
- Summary page showing combined team stats
- Transfer items between players
- Auto-reconnect support
- Disconnect handling with rollback protection

**Status Bar:**
- Green dot: Connected and syncing
- Orange dot: Searching for peer
- Red dot: Disconnected or error

**Technical Details:**
- Service ID: `com.saare.gungeon_mate.mp.v1`
- Protocol version: Handshake validation
- Message types: Hello, Snapshot, Gift, Request, RequestResp, EndRun, Ping/Pong
- Snapshot includes: character, guns, items, coolness, curse, shrines used, timestamp

### 8. Statistics & Summary

**Screens:** `StatsDetailScreen`, `SummaryPage`

**Individual Stats:**
- Average DPS
- Total DPS
- Inventory composition (guns, actives, passives, companions)
- Quality breakdown

**Team Summary (Multiplayer):**
- Combined average DPS
- Combined total DPS
- Combined total worth (sell prices)
- Combined quality score (0-100)
- Quality tier breakdown
- Top gun across both players
- Synergy potential count
- Active synergies across both players

---

## Data Management

### Data Sources

All game data is parsed from Enter the Gungeon wiki:
- `assets/data/guns.json` (239 guns)
- `assets/data/items.json` (270 items)
- `assets/data/synergies.json` (395 synergies)
- `assets/data/shrines.json` (8 shrines)
- `assets/data/gungeoneers.json` (9 characters)
- `assets/data/back_refs.json` (cross-reference index)

### Persistence

**Run State:**
- Saved to SharedPreferences as `current_run`
- Auto-saves on every inventory change
- Includes: main player, coop player (if active), coolness, curse, shrines used

**Favourites:**
- Saved to SharedPreferences as `favourites_v1`
- Shared across runs and both players

**Settings:**
- Theme mode (light/dark/system)
- Custom theme colors

---

## Architecture

### State Management

- **Provider pattern** with ChangeNotifier
- **RunProvider**: Manages run state, inventory, synergies, data loading
- **MultiplayerSession**: Manages multiplayer connection state and protocol
- **AppTheme**: Manages theme settings

### Key Components

**Models:**
- `Gun`, `Item`, `Synergy`, `Shrine`, `Gungeoneer`, `Player`, `RunState`
- `MpMessage` hierarchy for multiplayer protocol

**Screens:**
- `HomeScreen`: Main navigation hub
- `MainMenuScreen`: Character selection
- `ActiveRunScreen`: Inventory management
- `BrowseScreen`: Search and add items
- `SynergiesOverviewScreen`: View synergies
- `ShrinePickerScreen`: Activate shrines
- `StatsDetailScreen`: View statistics
- `SummaryPage`: Team summary (multiplayer)
- `MultiplayerLobbyScreen`: MP role selection
- `MultiplayerScreen`: MP session UI

**Services:**
- `MultiplayerService`: Low-level Bluetooth wrapper
- `MultiplayerSession`: High-level MP state machine
- `AppTheme`: Theme management
- `EffectTagger`: Tags item effects
- `ElementalTagger`: Tags elemental damage types

**Widgets:**
- `QualityBadge`: Quality indicator
- `RichLinkText`: Render rich text with clickable links
- `PeriodicTile`: Shrine activation tile
- `GungeoneerHeader`: Character header with stats
- `InventoryListRow`: Inventory row component
- `ThemeOverlay`: Per-theme visual effects

---

## Multiplayer Protocol

### Connection Flow

1. **Main Player**: Starts advertising with nickname and character
2. **Sidekick**: Starts discovery, finds Main's endpoint
3. **Auto-accept**: Both devices auto-accept connection
4. **Handshake**: Exchange Hello messages with protocol version validation
5. **Connected**: Exchange initial snapshots, start heartbeat
6. **Live sync**: Broadcast snapshots on inventory changes (200ms debounce)

### Message Types

- **MpHello**: Handshake with role, character, nickname, protocol version
- **MpSnapshot**: Full inventory state with timestamp (LWW conflict resolution)
- **MpGift**: Send gun/item to peer (with rollback on failure)
- **MpRequest**: Ask peer for item (with 30s timeout)
- **MpRequestResp**: Accept/deny request
- **MpEndRun**: Signal run end (tears down both sessions)
- **MpPing/MpPong**: Heartbeat for watchdog

### Conflict Resolution

- **Last-write-wins** on snapshots (timestamp-based)
- **Rollback** on gift send failure (prevents item loss)
- **Request deduplication** by request ID
- **Role-aware slot mapping** (Main ↔ Sidekick data routing)

---

## Tech Stack

- **Flutter 3.7+**
- **Provider** (state management)
- **shared_preferences** (persistence)
- **nearby_connections** (Bluetooth P2P)
- **permission_handler** (runtime permissions)
- **intl** (formatting)

---

## Project Structure

```
gungeon_mate/
├── lib/
│   ├── main.dart
│   ├── models/          # Data models
│   ├── providers/       # State management
│   ├── screens/         # UI screens
│   ├── services/        # Business logic
│   ├── widgets/         # Reusable widgets
│   └── utils/           # Utilities
├── assets/
│   ├── data/            # JSON game data
│   ├── images/          # Item/gun images
│   └── animations/      # GIF animations
├── android/             # Android build config
├── ios/                 # iOS build config
└── pubspec.yaml         # Dependencies
```

---

## Permissions

### Android

Required for multiplayer:
- `BLUETOOTH_ADVERTISE`
- `BLUETOOTH_CONNECT`
- `BLUETOOTH_SCAN`
- `NEARBY_WIFI_DEVICES`
- `ACCESS_FINE_LOCATION` (legacy Bluetooth discovery)

---

## Known Limitations

- Multiplayer requires Android (Nearby Connections is Android-only)
- iOS not supported (Nearby Connections unavailable)
- Bluetooth range limited to ~10 meters
- Large orders (15+ items) may hit BLE message size limit (512 bytes)

---

## Version History

### v0.9.6 (Current)
- Removed debug print statements for production
- Cleaned up documentation
- Version bump for release preparation

### v0.5.1
- Multiplayer status bar with connection indicator
- Role-aware page labels
- Increased watchdog timeout to 30s
- P0 bug fixes for multiplayer stability

---

## License

This is a companion app for Enter the Gungeon. All game data is sourced from the official wiki and belongs to Dodge Roll Games.
