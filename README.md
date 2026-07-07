# Gungeon Mate

<p align="center">
  <img src="assets/images/GM-logo.png" width="340" style="border: 4px solid #FF007F; border-radius: 16px; box-shadow: 0 0 25px rgba(255, 0, 127, 0.4);" alt="Gungeon Mate Banner">
</p>

<p align="center">
  <b>YOUR COMPANION IN THE GUNGEON</b><br>
  The ultimate high-performance offline companion app for Enter the Gungeon.<br>
  Track runs, master guns & items, activate local co-op, and conquer the Gungeon.
</p>

<p align="center">
  <img alt="Version" src="https://img.shields.io/badge/version-1.1.0-00E5FF?style=flat-square&logo=flutter">
  <img alt="Platform" src="https://img.shields.io/badge/platform-Android-FF007F?style=flat-square">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-E040FB?style=flat-square">
</p>

---

## 📥 DOWNLOAD & DEPLOY

<p align="center">
  <a href="https://github.com/Thothius/GungeonMate/releases/latest/download/gungeon-mate-v1.1.0.apk">
    <img src="https://img.shields.io/badge/%F0%9F%93%A5_DOWNLOAD_APK-v1.1.0-FF007F?style=for-the-badge&labelColor=1E1E22&color=FF007F" height="80" alt="Download APK" style="box-shadow: 0 0 30px rgba(255, 0, 127, 0.6); border-radius: 12px;">
  </a>
</p>

***Attention Gungeoneers!** Gungeon Mate has hit v1.0! Grab the latest signed APK from the [Releases page](https://github.com/Thothius/GungeonMate/releases/latest) and sideload it directly — no Play Store, no account, no ads, no internet required.*

---

## 🧮 v1.1.0 — UNIVERSAL DAMAGE CALCULATOR & UI POLISH

Every Gungeoneer now gets a live Damage Calculator on their dashboard, plus a pass of contrast fixes across Settings and the active-run header/inventory cards:

* **Universal Damage Calculator:** A collapsible DPS terminal on the run dashboard sums quantifiable "Damage Up"/"Damage Down" effects from your equipped guns and items into a single multiplier, applied live to every gun's DPS. Toggle it in Settings → Run Utilities → Dashboard Display.
* **Tactical Stats Card Redesign:** Removed the muddy low-opacity background icon on tactical-stats inventory cards; cards are now solid-backed with a crisp small icon next to the name.
* **Contrast Overhaul:** Boosted background opacity across Settings panels and the run dashboard's stat chips so everything stays legible over any custom wallpaper.

Also carried over from prior wiki-verification passes: 239 guns and 270 items audited field-by-field against the official Enter the Gungeon Wiki, stamped with a "Neckbear's Approval" 🐻 medal wherever verified.

---

## 🔫 PREMIUM FEATURES

### 👾 3D Glitch Cinematic Entry
Enter GungeonMate through a jaw-dropping **12fps stop-motion cyber breach**! Experience a first-person perspective flythrough down a neon-circuit wireframe 3D corridor. Blocks float by on a 45-degree snapping grid before a colossal **wholesome bullet-hell explosion** shatters the viewport, scattering physical dithered pixel debris that falls under active gravity to reveal the home screen. Includes a real-time **Web Audio API synthesizer** generating authentic 16-bit laser and bass-slam SFX!

### 🔮 Premium Glassmorphic UI (Frosted Glass)
To prevent active custom wallpapers from bleeding through and obscuring statistics, the panels have been upgraded with a **high-performance frosted glass (Glassmorphic) design**. Using `BackdropFilter` hardware-accelerated blurring (`sigmaX: 12.0`), information panels blur background detail into a soft glow while keeping text, gun metrics, and active synergies razor-sharp and legible in any lighting.

### 🖼️ Gyroscopic Parallax Wallpaper Lab
Take control of the Gungeon's visual dimensions! Backgrounds tilt and sway dynamically based on real-time hardware accelerometer tilt readings, with a full library of animated and hand-drawn dithered backdrops to choose from in the Style Lab.

---

## ⚔️ CORE CAPABILITIES

* 🛸 **Dynamic Run Tracking:** Auto-loads character profiles (Hunter, Robot, etc.) and tracks active Coolness, Curse, and synergistic item relationships in real-time.
* 📊 **Optimized UI Layouts:** Fast toggle between *Classic Periodic Grid* (compact) and *Tactical Stats* (comprehensive split-panel view with real-time stats and background gun overlays).
* 🧪 **The Style Lab:** Customize the app visual flair with accelerated particle emitters, custom font presets, and trippy backgrounds.
* 📶 **Zero-Internet Local Co-Op:** Sync active run states in real-time with dual-device co-op handshaking using high-speed, 100% offline Bluetooth + Wi-Fi Direct.

---

## 📱 LOCAL CO-OP HANDSHAKE

```
 📱 Player 1 (Main Host)               📱 Player 2 (Sidekick Cultist)
┌─────────────────────────┐           ┌─────────────────────────┐
│ Generates Session PIN   │           │ Enters PIN & Scans      │
│     e.g., [ 5291 ]      │ ──[PIN]──>│                         │
└────────────┬────────────┘           └────────────┬────────────┘
             │                                     │
             ▼                                     ▼
     [ Bluetooth Beacon ] <────────────────> [ Local Search ]
             │                                     │
             └───────────[ Secure Handshake ]──────┘
                                 │
                                 ▼
                     ⚡ INVENTORIES SYNCHRONIZED ⚡
```

1. **Host:** Selects **Main Role** on the Character screen to generate a 4-digit Session PIN.
2. **Cultist:** Selects **Sidekick Role**, enters the PIN, and starts scanning.
3. **Sync:** Both devices handshake securely and synchronize all active inventories and stats in milliseconds!

---

## 📜 DISCLAIMER

*Gungeon Mate is an unofficial, completely free fan-made companion app built out of pure love and dedication for the Gungeon community. All rights to "Enter the Gungeon" belong to Dodge Roll and Devolver Digital. All item stats, descriptions, and synergy data are sourced from the official Enter the Gungeon Wiki at [wiki.gg](https://enterthegungeon.wiki.gg).*

<p align="center">
  <i>Made with 💜 for the Gungeon community. Gungeon Mate is free forever.</i><br>
  <b>v1.1.0 — Bug Fixes & Ready to Roll!</b>
</p>
