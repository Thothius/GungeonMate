# GungeonMate — UI/UX Issues & Backlog

The following is a curated list of UI/UX improvements identified in GungeonMate to make the companion experience even sleeker:

---

## 1. Inventory Grid Sizing on Small Phones
- **Issue:** On devices with small screens (e.g., standard iPhone SE or compact Android models), the 3-column periodic active run inventory tiles can feel tight, and long item names may still wrap or clip slightly.
- **Proposed Fix:** Make the column count dynamic (e.g. 3 columns by default, but toggleable to 2 columns in settings), or automatically truncate text at a smaller dynamic boundary based on layout constraints.

## 2. Multi-Item Rapid Addition
- **Issue:** When selecting multiple items in the Browse Screen, having to tap, view details, go back, and repeat can slow down the user's flow.
- **Proposed Fix:** Add a quick "＋" button directly on the Browse Grid tiles to add guns/items to P1 or P2 in one tap, bypassing the Detail Screen entirely.

## 3. Dark Theme Particle Density Setting
- **Issue:** Very bright/dense particle presets (like Firestorm embers or Unicorn sparkles) might look incredibly beautiful, but can make text slightly harder to read in low-light environments.
- **Proposed Fix:** Add a "Subtle" mode toggle in Settings to reduce particle count by 50% for all presets without turning them off completely.

## 4. Cooperative Session Disconnect Recovery
- **Issue:** If Bluetooth/WiFi signal drops briefly during a co-op Gungeon run, players must manually restart the connection lobby from the multiplayer screen.
- **Proposed Fix:** Implement a background retry hook that automatically re-establishes connections and mirrors inventories seamlessly when the device comes back in range.
