# GungeonMate — Feature Analysis & Code Architecture

This document maps all core production features of the GungeonMate app and details their directory paths, primary services, and state files.

---

## 1. Core Run Inventory State & Tracker
- **Directory:** `@/lib/providers/run_provider.dart` and `@/lib/models/run_state.dart`
- **Responsibility:** Manages the active run's player choice, inventory list (guns, active items, passive items), stat adjustments (curse, keys, casings, armor), and cooperative player inventory sync.
- **Future Modifications:** To add custom items or new characters, append them inside `@/lib/models/gungeoneer.dart`, `@/lib/models/gun.dart`, or `@/lib/models/item.dart`.

## 2. Dynamic 3D Layered Particle Engines
- **Directory:** `@/lib/widgets/theme_overlay.dart` and `@/lib/services/app_theme.dart`
- **Responsibility:** Handles 12 handmade aesthetic styles that render particles both behind dashboards (translucent layer) and over dashboards (foreground layer) with physical device tilt/gyroscope sways via `sensors_plus`.
- **Future Modifications:** Customize individual painters (e.g. `_GoldDustPainter`, `_ToxicBubblesPainter`) inside `@/lib/widgets/theme_overlay.dart`.

## 3. Local Wiki & Synergy Solver
- **Directory:** `@/lib/screens/item_detail_screen.dart` and `@/lib/widgets/wiki_sections.dart`
- **Responsibility:** Solves active/missing item synergies on the fly based on current inventory, and serves fully offline descriptions, statistics, and lore. Includes instant direct external browser redirects when pressing the book icon.
- **Future Modifications:** Modify synergy matching algorithms inside `@/lib/models/synergy.dart`.

## 4. Local-First Multiplayer Sync
- **Directory:** `@/lib/services/multiplayer_session.dart` and `@/lib/services/multiplayer_service.dart`
- **Responsibility:** Seamless cooperative player tracking and inventory mirroring via Google Nearby Connections (Bluetooth & WiFi Direct peer-to-peer syncing).
- **Future Modifications:** Adjust protocol packet types inside `@/lib/models/multiplayer_messages.dart`.
