# MacStats 📊

> A lightweight, native macOS Menu Bar status monitor built with Swift. Real-time CPU usage, RAM stats, Network speeds, and CPU temperature at a glance.

🌐 [English](README.md) | [Tiếng Việt](README.vi.md) | [简体中文](README.zh.md) | [日本語](README.ja.md)

![macOS 11.0+](https://img.shields.io/badge/macOS-11.0%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.0-orange?logo=swift)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ⚡ Quick Start

### 📦 1-Command Download & Install
Run this single command in your Terminal to download, build/extract, and install **MacStats** directly to `/Applications`:

```bash
curl -fsSL https://raw.githubusercontent.com/openhoangnc/mac-stats/main/install.sh | bash
```

---

### 🗑️ 1-Command Uninstall All
To completely stop MacStats, remove launch at startup items, clear user preferences, and delete `/Applications/MacStats.app`:

```bash
curl -fsSL https://raw.githubusercontent.com/openhoangnc/mac-stats/main/uninstall.sh | bash
```

---

## ✨ Features

- 🚀 **Ultra Lightweight & Fast**: Native Swift application with extremely low memory and CPU footprint. No Xcode project or heavy dependencies required.
- 📊 **Three-Column Menu Bar View**:
  - **Left Column (Network)**: Real-time Upload (top) and Download (bottom) network speeds with auto-scaling unit (`B`, `K`, `M`, `G`) and speed-based color coding.
  - **Middle Column (CPU/Memory)**: Live CPU usage (`%`) (top) and memory usage in gigabytes (`G`) (bottom) with usage-based color coding.
  - **Right Column (Temperature)**: CPU average temperature (top) and unit (`°C` or `°F`) (bottom) with dynamic temperature-based color coding.
- ⚙️ **Settings Context Menu**: Click or right-click the menu bar status item to inspect options:
  - **Launch at Login**: Toggle automatic startup upon macOS user login (uses `SMAppService` on macOS 13+ with fallback LaunchAgents plist on older systems).
  - **Update Interval**: Custom update frequency selection (1s, 2s, or 5s).
  - **Temperature Unit**: Choose Celsius (`°C`) or Fahrenheit (`°F`).
  - **GitHub Repository**: Direct link to the repository page.
  - **Quit MacStats**: Close the application.
- 🧠 **Dynamic SMC Temperature Scanning**: Automatically scans for active Intel and Apple Silicon (M1/M2/M3/M4/M5) temperature sensor keys at startup (checking efficiency cores, performance cores, base CPU and Pro/Max/Ultra/General keys) and calculates the real-time average.
- ⚡ **Performance & Memory Optimizations**:
  - Runs as an accessory (`LSUIElement`) app so it has no Dock or Application switcher footprint.
  - Employs active memory trim (`malloc_zone_pressure_relief`) on startup and periodically (every 30 seconds) to prevent heap fragmentation.
  - Sets timer tolerance (25% of the interval) to allow macOS to coalesce timer events and save battery power.
- 🤖 **Automated GitHub Release & Versioning**: Built-in GitHub Actions workflow automatically builds `.app` releases, bumps semantic version numbers, and creates GitHub releases.

---

## 🛠️ CLI arguments & Manual Control
The compiled binary supports the following arguments:
- `--cleanup-login-item` / `--uninstall-login-item` / `--uninstall`: unregisters `SMAppService` login items, removes user LaunchAgents plist files, cleans user default properties, and exits immediately.

If you prefer to compile from source manually:

1. Clone the repository:
   ```bash
   git clone https://github.com/openhoangnc/mac-stats.git
   cd mac-stats
   ```

2. Run the build script:
   ```bash
   ./build.sh
   ```

3. Launch the application:
   ```bash
   open MacStats.app
   ```

---

## 🤖 CI/CD & Auto-Versioning

MacStats includes a GitHub Actions workflow in `.github/workflows/release.yml`.

- **Automatic Version Bumping**: Increments version numbers (`v1.0.0` → `v1.0.1`) on every release push or manual dispatch.
- **Automated Releases**: Compiles native macOS binary bundle, packages `MacStats.zip`, creates a GitHub Release, and uploads artifacts.

---

## 📄 License

This project is licensed under the MIT License.
