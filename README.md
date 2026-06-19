# Gungeon Mate

<p align="center">
  <img src="assets/images/GM-logo.png" width="340" style="border: 4px solid #FF2A6D; border-radius: 16px; box-shadow: 0 0 20px #FF2A6D;" alt="Gungeon Mate Banner">
</p>

<p align="center">
  <b>YOUR COMPANION IN THE GUNGEON</b><br>
  The ultimate high-performance offline companion app for Enter the Gungeon.<br>
  Track runs, master guns & items, activate local co-op, and conquer the Gungeon.
</p>

<p align="center">
  <img alt="Version" src="https://img.shields.io/badge/version-0.9.4-00D2FF?style=flat-square&logo=flutter">
  <img alt="Platform" src="https://img.shields.io/badge/platform-Android-6C5CE7?style=flat-square">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-00B894?style=flat-square">
</p>

---

## 📥 DOWNLOAD & DEPLOY

<p align="center">
  <a href="https://github.com/Thothius/GungeonMate/raw/master/builds/gungeon-mate-v0.9.4.apk">
    <img src="https://img.shields.io/badge/%F0%9F%93%A5_DOWNLOAD_APK-v0.9.4-FF2A6D?style=for-the-badge&labelColor=1E1E22&color=FF2A6D" height="48" alt="Download APK" style="box-shadow: 0 0 15px rgba(255, 42, 109, 0.4);">
  </a>
</p>

***Attention Gungeoneers!** The latest v0.9.4 production release has been compiled as `GungeonMate-v0.9.4.apk` on your desktop for instant sideloading! Download it directly to play.*

---

## 🔫 CORE FEATURES

* 🛸 **Dynamic Run Tracking:** Auto-loads character profiles (Hunter, Robot, etc.) and tracks active Coolness, Curse, and synergistic item relationships in real-time.
* 📊 **Optimized UI Layouts:** Fast toggle between *Classic Periodic Grid* (compact) and *Tactical Stats* (comprehensive split-panel view with real-time stats and background gun overlays).
* 🧪 **The Style Lab:** Customize the app visual flair with accelerated particle emitters, custom font presets, and trippy backgrounds.
* 📶 **Zero-Internet Local Co-Op:** Sync active run states in real-time with dual-device co-op handshaking using high-speed, 100% offline Bluetooth + Wi-Fi Direct.

---

## � LOCAL CO-OP HANDSHAKE

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

##  DISCLAIMER

*Gungeon Mate is an unofficial, completely free fan-made companion app built out of pure love and dedication for the Gungeon community. All rights to "Enter the Gungeon" belong to Dodge Roll and Devolver Digital. All item stats, descriptions, and synergy data are sourced from the official Enter the Gungeon Wiki at [wiki.gg](https://enterthegungeon.wiki.gg).*

<p align="center">
  <i>Made with 💜 for the Gungeon community. Gungeon Mate is free forever.</i><br>
  <b>v0.9.4 — Road to July Launch!</b>
</p>
