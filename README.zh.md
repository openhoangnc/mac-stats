# MacStats 📊

> 一款使用 Swift 开发的 macOS 菜单栏状态监控工具。极其轻量、原生体验。CPU 使用率、内存占用、网速和 CPU 温度，扫一眼即可轻松掌握。

🌐 [English](README.md) | [Tiếng Việt](README.vi.md) | [简体中文](README.zh.md) | [日本語](README.ja.md)

![macOS 11.0+](https://img.shields.io/badge/macOS-11.0%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.0-orange?logo=swift)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ⚡ 快速开始

### 📦 一键下载与安装
在终端 (Terminal) 中运行以下命令，即可全自动完成下载、解压并安装 **MacStats** 到 `/Applications` 目录：

```bash
curl -fsSL https://raw.githubusercontent.com/openhoangnc/mac-stats/main/install.sh | bash
```

---

### 🗑️ 一键干净卸载
想要完全卸载 MacStats，清理开机启动项以及用户偏好设置，并删除应用程序文件，请运行：

```bash
curl -fsSL https://raw.githubusercontent.com/openhoangnc/mac-stats/main/uninstall.sh | bash
```

---

## ✨ 核心特性

- 🚀 **极度轻量且飞快**：原生 Swift 开发，内存和 CPU 占用几乎可以忽略不计。没有臃肿的 Xcode 工程，零第三方依赖。
- 📊 **三列式菜单栏展示**：
  - **左列 (网络)**：实时显示 上传（上）和 下载（下）网速。单位自动缩放（`B`, `K`, `M`, `G`），并会根据当前网速动态变色。
  - **中列 (CPU/内存)**：显示 CPU 使用率（上）和 内存占用量 G（下）。当负载升高时颜色会自动从绿变红。
  - **右列 (温度)**：显示 CPU 平均温度（上）和 温度单位（下）。颜色同样会根据温度高低自动变化。
- ⚙️ **快捷设置菜单**：左键或右键点击菜单栏图标即可唤出：
  - **Launch at Login (开机启动)**：一键开启/关闭开机自启。macOS 13+ 使用原生的 `SMAppService`，老系统则自动降级使用 LaunchAgents plist。
  - **Update Interval (刷新频率)**：支持自定义刷新时间（1秒、2秒 或 5秒）。
  - **Temperature Unit (温度单位)**：切换摄氏度 (`°C`) 和华氏度 (`°F`)。
  - **GitHub Repository**：直达本项目源码库。
  - **Quit MacStats (退出)**：完全退出程序。
- 🧠 **动态 SMC 温度传感器扫描**：启动时自动扫描适配的 Intel 和 Apple Silicon (M1/M2/M3/M4/M5) 温度传感器（智能遍历能效核、性能核及各类核心温度键值），精准计算出实时平均温度。
- ⚡ **深度内存与性能优化**：
  - 作为后台辅助程序 (`LSUIElement`) 运行，不会在 Dock 栏出现，也不会在 Command-Tab 切换时打扰你。
  - 主动进行内存整理：在应用启动时及运行期间（每 30 秒）调用 `malloc_zone_pressure_relief`，彻底告别内存碎片和泄露。
  - 设置了合理的定时器容差 (Tolerance)，允许 macOS 将定时任务与其他系统事件合并执行，显著降低电池消耗。
- 🤖 **全自动的发布流水线 (CI/CD)**：借助 GitHub Actions，每次更新都会自动构建 `.app`、递增语义化版本号，并发布最新的 GitHub Release。

---

## 🛠️ CLI 参数与手动编译
内置支持以下命令行参数，方便静默管理：
- `--cleanup-login-item` / `--uninstall-login-item` / `--uninstall`：静默注销 `SMAppService`，删除 LaunchAgents plist 文件及用户配置，然后立刻退出。

如果你更喜欢克隆源码自己编译：

1. 克隆代码库：
   ```bash
   git clone https://github.com/openhoangnc/mac-stats.git
   cd mac-stats
   ```

2. 执行构建脚本：
   ```bash
   ./build.sh
   ```

3. 运行应用：
   ```bash
   open MacStats.app
   ```

---

## 🤖 CI/CD 与自动化版本控制

本项目通过 `.github/workflows/release.yml` 实现了完善的持续集成与发布：

- **自动打版升级**：当推送代码或手动触发时，版本号会自动递增（例如：`v1.0.0` → `v1.0.1`）。
- **自动化构建发布**：全自动编译原生 macOS 应用程序包并压缩为 `MacStats.zip`，随后直接发布到 GitHub Releases 供用户下载。

---

## 📄 许可协议

本项目基于 MIT License 协议开源。
