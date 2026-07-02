# MacStats 📊

> A lightweight, native macOS Menu Bar status monitor built with Swift. Real-time CPU usage, RAM stats, and Network speeds at a glance.

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

- 🚀 **Ultra Lightweight & Fast**: Native Swift application with low memory and CPU footprint. No Xcode project or heavy dependencies required.
- 📊 **Dual Column Menu Bar View**:
  - **Left Column**: Upload (`▲`) & Download (`▼`) network speeds with auto-scaling unit (`B`, `K`, `M`, `G`) and dynamic bandwidth color coding.
  - **Right Column**: Live CPU usage (`%`) & Memory consumption (`G`) with smart color warning thresholds (Green → Yellow → Red).
- ⚙️ **Detailed System Popover**: Click the menu bar icon to inspect:
  - Detailed CPU utilization breakdown (User, System, Idle, Active Cores).
  - RAM breakdown (Active, Wired, Compressed, Free, Total).
  - Active Network interface name, upload/download rates, and total session transfer counters.
  - Custom update interval selection (1s, 2s, 5s).
- 🔄 **Launch at Login / Startup**: Toggle automatic startup upon macOS user login directly from the menu bar status menu (`✓ Launch at Login`).
- 🤖 **Automated GitHub Release & Versioning**: Built-in GitHub Actions workflow automatically builds `.app` releases, bumps semantic version numbers, and creates GitHub releases.

---

## 🛠️ Manual Build & Installation

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
