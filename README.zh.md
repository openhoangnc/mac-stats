# MacStats 📊

> 一个使用 Swift 构建的轻量级、原生 macOS 菜单栏状态监控器。实时掌握 CPU 使用率、RAM 统计、网络速度以及 CPU 温度。

🌐 [English](README.md) | [Tiếng Việt](README.vi.md) | [简体中文](README.zh.md) | [日本語](README.ja.md)

![macOS 11.0+](https://img.shields.io/badge/macOS-11.0%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.0-orange?logo=swift)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ⚡ 快速开始

### 📦 一键下载与安装
在终端（Terminal）中运行此单行命令，即可自动下载、构建/解压，并将 **MacStats** 直接安装到 `/Applications` 目录中：

```bash
curl -fsSL https://raw.githubusercontent.com/openhoangnc/mac-stats/main/install.sh | bash
```

---

### 🗑️ 一键完全卸载
如需完全停止 MacStats、移除开机启动项、清除用户偏好设置，并删除 `/Applications/MacStats.app`：

```bash
curl -fsSL https://raw.githubusercontent.com/openhoangnc/mac-stats/main/uninstall.sh | bash
```

---

## ✨ 功能特性

- 🚀 **极其轻量与快速**：原生 Swift 应用程序，占用极低的内存和 CPU 资源。无需 Xcode 项目，亦无臃肿的外部依赖。
- 📊 **三列式菜单栏视图**：
  - **左列（网络）**：实时上传（上行）和下载（下行）网络速度，支持自动缩放单位（`B`、`K`、`M`、`G`），并根据带宽速度动态调整文本颜色。
  - **中列（CPU/内存）**：实时 CPU 使用率（`%`，上行）和内存占用（`G`，下行），具有基于使用情况的智能颜色警告阈值。
  - **右列（温度）**：CPU 平均温度（上行）和单位（`°C` 或 `°F`，下行），基于温度值动态调整文字颜色。
- ⚙️ **设置上下文菜单**：左键或右键点击菜单栏状态图标，即可展开以下选项：
  - **开机启动（Launch at Login）**：一键切换是否在 macOS 用户登录时自动运行（在 macOS 13+ 上使用 `SMAppService`，旧版本系统则自动回退至 LaunchAgents plist 配置）。
  - **更新间隔（Update Interval）**：自定义更新频率（1 秒、2 秒或 5 秒）。
  - **温度单位（Temperature Unit）**：选择摄氏度（`°C`）或华氏度（`°F`）。
  - **GitHub 仓库**：直接打开项目 GitHub 主页的链接。
  - **退出 MacStats（Quit MacStats）**：安全退出并关闭应用程序。
- 🧠 **动态 SMC 温度扫描**：在启动时自动扫描 Intel 与 Apple Silicon（M1/M2/M3/M4/M5）温度传感器（检测效率核心、性能核心、基础 CPU 和 Pro/Max/Ultra/General 的 SMC 键），并计算实时的平均 CPU 温度。
- ⚡ **性能与内存优化**：
  - 作为辅助型应用（`LSUIElement`）运行，不在 Dock 栏或 Command-Tab 应用切换器中展示，保持界面整洁。
  - 采用主动内存回收（在启动和每隔 30 秒时触发 `malloc_zone_pressure_relief`），释放未使用的堆内存以防止内存碎片化。
  - 设置定时器容差（时间间隔的 25%），允许 macOS 自动合并定时器事件以节省电池电量。
- 🤖 **自动化 GitHub 发布与版本控制**：内置 GitHub Actions 工作流，可自动构建 `.app` 版本、递增语义化版本号并创建 GitHub Release。

---

## 🛠️ 命令行参数与手动控制
编译后的二进制文件支持以下命令行参数：
- `--cleanup-login-item` / `--uninstall-login-item` / `--uninstall`：注销 `SMAppService` 登录项，移除用户 LaunchAgents 目录下的 plist 文件，清除用户偏好设置，并立即退出程序。

如果您更倾向于手动从源码编译：

1. 克隆仓库：
   ```bash
   git clone https://github.com/openhoangnc/mac-stats.git
   cd mac-stats
   ```

2. 运行构建脚本：
   ```bash
   ./build.sh
   ```

3. 运行应用程序：
   ```bash
   open MacStats.app
   ```

---

## 🤖 CI/CD 与自动版本控制

MacStats 包含了位于 `.github/workflows/release.yml` 的 GitHub Actions 工作流。

- **自动版本递增**：在每次向主分支推送代码或手动调度时，自动递增版本号（例如 `v1.0.0` → `v1.0.1`）。
- **自动化发布**：编译原生 macOS 应用程序包、打包成 `MacStats.zip`、自动创建 GitHub Release 并上传构建产物。

---

## 📄 开源许可证

本项目基于 MIT 许可证开源。
