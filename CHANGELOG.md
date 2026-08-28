# Changelog

All notable changes to `BlueStacks Debloater & Optimizer` are documented in this file.

---

## [1.0.0] - Standalone & Bilingual Release

### Added
- **1-Click Self-Elevating Launchers:**
  - `iniciar.bat`: Automatic UAC elevation and 1-click execution for standard users.
  - `restaurar.bat`: 1-click rollback restoring the most recent backup.
  - `menu.bat`: Interactive menu offering granular debloat options (Host-only, Guest-only, Dry-Run preview, Status diagnostics).
- **Native Bilingual Support (PT-BR / EN):**
  - Automatic language detection based on Windows UI Culture.
  - Fully translated console output, status messages, and diagnostics.
  - Manual override via `-Language <pt|en>`.
- **Standalone Architecture:**
  - Decoupled from `universal-debloater` into a dedicated repository.
  - Automatic BlueStacks 5 (nxt) and MSI App Player detection from 32-bit and 64-bit Windows registry.
  - Self-contained logging and timestamped backup storage in `state/backups/bluestacks/`.
- **Performance Optimizations:**
  - Hardware ASTC decoding enabled (`astc_decoding_mode="hardware"`).
  - Unlocked high framerate mode up to 120 FPS (`enable_high_fps="1"`, `max_fps="120"`).
  - Disabled v-sync for lower input latency (`enable_vsync="0"`).
- **Host-Side Telemetry & Ad Debloat:**
  - Dynamic discovery and disabling of ad, promo, campaign, banner, nowbux, and AI keys in `bluestacks.conf`.
  - Read-Only lock applied to `bluestacks.conf` to prevent BlueStacks from restoring ads on relaunch.
  - Null-routing (`0.0.0.0`) of telemetry and ad domains in Windows `hosts` file with DNS cache flush.
  - Non-essential background helpers renamed to `.bak` (`BlueStacksHelper.exe`, `BlueStacksAI.exe`, `HD-LogCollector.exe`, `BlueAI` folder).
- **Guest-Side Android Debloat via ADB:**
  - Local ADB connection handling and automatic instance boot via `HD-Player.exe` when offline.
  - Null-routing of tracking domains in Android `/system/etc/hosts`.
  - Discovery and safe disabling of pre-installed bloatware packages via `pm disable-user --user 0`.
- **Automated Verification:**
  - Dedicated test suite in `tests/Test-BlueStacksDebloater.ps1`.
