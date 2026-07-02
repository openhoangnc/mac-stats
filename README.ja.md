# MacStats 📊

> Swiftで構築された、軽量でネイティブなmacOSメニューバーステータスモニター。リアルタイムのCPU使用率、RAM統計、ネットワーク速度、およびCPU温度を一目で確認できます。

🌐 [English](README.md) | [Tiếng Việt](README.vi.md) | [简体中文](README.zh.md) | [日本語](README.ja.md)

![macOS 11.0+](https://img.shields.io/badge/macOS-11.0%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.0-orange?logo=swift)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ⚡ クイックスタート

### 📦 1行コマンドでのダウンロードとインストール
ターミナル（Terminal）で以下のコマンドを実行するだけで、**MacStats** を自動的にダウンロード、ビルド/展開し、`/Applications` ディレクトリにインストールできます：

```bash
curl -fsSL https://raw.githubusercontent.com/openhoangnc/mac-stats/main/install.sh | bash
```

---

### 🗑️ 1行コマンドでの完全アンインストール
MacStats を完全に終了し、自動起動設定を削除し、ユーザーの環境設定をクリアし、`/Applications/MacStats.app` を削除する場合：

```bash
curl -fsSL https://raw.githubusercontent.com/openhoangnc/mac-stats/main/uninstall.sh | bash
```

---

## ✨ 機能と特徴

- 🚀 **極めて軽量＆高速**: CPUやメモリへの負荷を最小限に抑えたネイティブのSwiftアプリケーション。Xcodeプロジェクトや重い外部ライブラリは一切不要です。
- 📊 **3列構成のメニューバー表示**:
  - **左列 (ネットワーク)**: リアルタイムの送信（上り、上段）および受信（下り、下段）速度。速度に合わせて自動で単位がスケーリング（`B`, `K`, `M`, `G`）され、帯域幅に応じた動的なカラーコーディングが適用されます。
  - **中央列 (CPU/メモリ)**: リアルタイムのCPU使用率（`%`, 上段）およびメモリ使用量（GB単位の`G`, 下段）。使用量に応じたスマートな警告色（緑 → 黄 → 赤）が表示されます。
  - **右列 (温度)**: CPUの平均温度（上段）と単位（`°C` または `°F`, 下段）。温度に応じて動的にテキストの色が変化します。
- ⚙️ **設定コンテキストメニュー**: ステータスバーのアイコンを左クリックまたは右クリックすると、以下の設定メニューが表示されます：
  - **ログイン時に開く (Launch at Login)**: macOS起動時の自動実行を切り替えます（macOS 13以降では `SMAppService` を使用し、それ以前の古いOSバージョンでは自動的に LaunchAgents plist ファイルへフォールバックします）。
  - **更新間隔 (Update Interval)**: データの更新頻度（1秒、2秒、5秒）をカスタマイズします。
  - **温度単位 (Temperature Unit)**: 摂氏（`°C`）または華氏（`°F`）を選択できます。
  - **GitHubリポジトリ**: プロジェクトのGitHubページを直接ブラウザで開きます。
  - **MacStatsを終了 (Quit MacStats)**: アプリケーションを終了します。
- 🧠 **動的なSMC温度スキャン**: 起動時にIntelおよびApple Silicon（M1/M2/M3/M4/M5）用の温度センサーSMCキー（効率コア、パフォーマンスコア、CPU全体、Pro/Max/Ultra/Generalのキーなど）を自動スキャンし、リアルタイムで平均温度を算出します。
- ⚡ **パフォーマンスとメモリの最適化**:
  - バックグラウンドエージェントアプリ（`LSUIElement`）として動作するため、Dockやアプリケーション切り替え（Command + Tab）には表示されません。
  - 起動時および定期的（30秒ごと）にアクティブなメモリ解放（`malloc_zone_pressure_relief`）をトリガーし、ヒープの断片化を防ぎます。
  - タイマーの許容誤差（tolerance）を設定（間隔の25%）することで、macOSがタイマーイベントを他のプロセスと同調して処理し、バッテリー消費を抑えるようにします。
- 🤖 **GitHubでの自動リリース＆バージョン管理**: リリース用のプッシュまたは手動実行時に、GitHub Actionsワークフローが自動的に `.app` をビルドし、セマンティックバージョニングに基づいてタグを更新し、GitHub Releaseを作成・アップロードします。

---

## 🛠️ コマンドライン引数と手動制御
ビルドされたバイナリは、以下のコマンドライン引数をサポートしています：
- `--cleanup-login-item` / `--uninstall-login-item` / `--uninstall`: `SMAppService` のログイン項目を登録解除し、ユーザーの LaunchAgents plist ファイルを削除し、環境設定の値をクリアして、即座に終了します。

ソースから手動でコンパイルする場合：

1. リポジトリをクローンします：
   ```bash
   git clone https://github.com/openhoangnc/mac-stats.git
   cd mac-stats
   ```

2. ビルドスクリプトを実行します：
   ```bash
   ./build.sh
   ```

3. アプリケーションを実行します：
   ```bash
   open MacStats.app
   ```

---

## 🤖 CI/CD と自動バージョン管理

MacStatsには、`.github/workflows/release.yml` にGitHub Actionsワークフローが構成されています。

- **自動バージョンアップ**: リリースのプッシュまたは手動実行のたびに、自動的にバージョン番号がインクリメントされます（例：`v1.0.0` → `v1.0.1`）。
- **自動リリース作成**: ネイティブのmacOSバイナリバンドルをコンパイルし、`MacStats.zip` にアーカイブし、GitHubリリースを作成してビルド成果物をアップロードします。

---

## 📄 ライセンス

本プロジェクトは MIT ライセンスの下でライセンスされています。
