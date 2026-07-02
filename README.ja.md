# MacStats 📊

> Swiftで開発された、軽量でネイティブなmacOSメニューバーステータスモニター。CPU使用率、メモリ（RAM）統計、ネットワーク速度、CPU温度をリアルタイムでひと目で確認できます。

🌐 [English](README.md) | [Tiếng Việt](README.vi.md) | [简体中文](README.zh.md) | [日本語](README.ja.md)

![macOS 11.0+](https://img.shields.io/badge/macOS-11.0%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.0-orange?logo=swift)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ⚡ クイックスタート

### 📦 1コマンドでダウンロード＆インストール
ターミナルを開き、以下のコマンドをコピー＆ペーストして実行するだけで、ダウンロードからビルド/解凍、`/Applications` へのインストールまでを全自動で行います：

```bash
curl -fsSL https://raw.githubusercontent.com/openhoangnc/mac-stats/main/install.sh | bash
```

---

### 🗑️ 1コマンドでクリーンアンインストール
MacStatsを完全に停止させ、ログイン時の自動起動設定やユーザー設定をクリアし、アプリケーション本体（`/Applications/MacStats.app`）を削除するには、以下のコマンドを実行してください：

```bash
curl -fsSL https://raw.githubusercontent.com/openhoangnc/mac-stats/main/uninstall.sh | bash
```

---

## ✨ 主な機能と特徴

- 🚀 **超軽量＆高速**: Swiftによるネイティブアプリであるため、CPUやメモリの消費量が極めて少ないのが特徴です。肥大化したXcodeプロジェクトや重い外部ライブラリは一切使用していません。
- 📊 **3列構成のメニューバー表示**:
  - **左列（ネットワーク）**: リアルタイムの上り（上段）および下り（下段）速度。通信量に応じて単位（`B`, `K`, `M`, `G`）が自動で調整され、速度に応じたカラーコーディングが適用されます。
  - **中央列（CPU/メモリ）**: CPU使用率（`%`, 上段）とRAM使用量（`G`, 下段）。負荷が高くなるとテキストの色が自動的に変化（緑→黄→赤）して警告します。
  - **右列（温度）**: CPUの平均温度（上段）と単位（`°C` または `°F`, 下段）。こちらも温度上昇に伴って色が変化します。
- ⚙️ **便利な設定メニュー**: メニューバーのアイコンをクリック（または右クリック）すると、以下のメニューが表示されます：
  - **Show Network Speeds（ネットワーク速度を表示）**: ネットワーク速度列の表示/非表示を切り替えます。
  - **Show CPU Temperature（CPU温度を表示）**: CPU温度列の表示/非表示を切り替えます。
  - **Launch at Login（ログイン時に起動）**: macOSログイン時の自動起動を切り替えます。macOS 13以降ではネイティブの `SMAppService` を利用し、古いOSでは自動的にLaunchAgents plistへフォールバックする安心設計です。
  - **Update Interval（更新間隔）**: データの更新頻度（1秒、2秒、または5秒）を好みに合わせて変更できます。
  - **Temperature Unit（温度単位）**: 摂氏（`°C`）と華氏（`°F`）を切り替えます。
  - **GitHub Repository**: 本プロジェクトのGitHubリポジトリをブラウザで開きます。
  - **Quit MacStats（終了）**: アプリケーションを終了します。
- 🧠 **高度なSMC温度センサースキャン**: 起動時にIntelおよびApple Silicon（M1/M2/M3/M4/M5）用の温度センサーSMCキー（Pコア、Eコア、システム全体のキーなど）を自動で網羅的にスキャンし、リアルタイムで正確な平均温度を割り出します。
- ⚡ **徹底したパフォーマンス＆メモリ最適化**:
  - バックグラウンドアプリ（`LSUIElement`）として動作するため、DockやCommand+Tabのアプリケーション切り替えには表示されず、作業の邪魔になりません。
  - 起動時および30秒ごとに `malloc_zone_pressure_relief` を呼び出してメモリの断片化を防ぎ、システムリソースを常にクリーンに保ちます。
  - タイマーの実行タイミングに許容誤差（tolerance、インターバルの25%）を設けることで、macOSがタイマーイベントを賢くまとめて処理し、バッテリー消費を大幅に削減します。
- 🤖 **CI/CDによる自動リリース**: GitHub Actionsワークフローを組み込んでおり、コードの更新に伴って自動でアプリをビルドし、バージョン番号を繰り上げ、GitHub Releasesへ公開します。

---

## 🛠️ CLIオプションと手動ビルド
コンパイル済みのバイナリは、以下のコマンドライン引数をサポートしています：
- `--cleanup-login-item` / `--uninstall-login-item` / `--uninstall`: `SMAppService` の登録解除、LaunchAgents plistの削除、ユーザー設定のクリアをサイレントに実行し、即座に終了します。

ご自身でソースコードからビルドしたい場合は、以下の手順に従ってください：

1. リポジトリのクローン：
   ```bash
   git clone https://github.com/openhoangnc/mac-stats.git
   cd mac-stats
   ```

2. ビルドスクリプトの実行：
   ```bash
   ./build.sh
   ```

3. アプリケーションの起動：
   ```bash
   open MacStats.app
   ```

---

## 🤖 CI/CD と自動バージョニング

プロジェクトには `.github/workflows/release.yml` にCI/CDのワークフローが用意されています。

- **自動バージョンアップ**: mainブランチへのプッシュや手動実行をトリガーとして、バージョン番号が自動的に加算されます（例：`v1.0.0` → `v1.0.1`）。
- **リリース自動化**: macOSアプリバンドルをビルドして `MacStats.zip` に圧縮し、変更内容とともにGitHub Releaseを作成します。

---

## 🧑‍💻 開発者向け：学ぶべきユニークな手法

このプロジェクトでは、macOS 開発においてあまり見られない、高度に最適化された手法をいくつか採用しています：

1. **Xcode不要のアプリバンドル構築**: このアプリは、Xcodeのプロジェクトファイルを一切使用せずに構築されています。代わりに、カスタムbashスクリプト (`build.sh`) を使用して、強力なサイズ最適化 (`-Osize`, `-wmo`, `-dead_strip`) と共に `swiftc` コンパイラを直接呼び出します。その後、手動で `.app` バンドル構造を構築します。これは、ターミナルとテキストエディタだけでネイティブなmacOS UIアプリを構築できることを証明しています。
2. **低レベルC APIの直接呼び出し**: CPUオーバーヘッドをほぼゼロにするため、アプリは高レベルな `Foundation` ラッパーをバイパスします。Swiftから生のメモリポインタを使用して、MachカーネルAPI (`host_processor_info`, `host_statistics64`) やBSDソケットAPI (`getifaddrs`) を直接呼び出します。
3. **メモリ割り当てゼロの文字列解析 (Zero-Allocation)**: ネットワークポーリングループ内では、インターフェイスがEthernet/Wi-Fiであるかを確認するためにSwiftの `String` を割り当てる（例: `name.hasPrefix("en")`）代わりに、生のC文字列バイトを直接比較します (`namePtr.pointee == 0x65 && namePtr.advanced(by: 1).pointee == 0x6e`)。これにより、高頻度のポーリングループ内でのメモリ割り当てを完全に排除しています。
4. **IOKitによるSMCの動的探索**: 温度センサーのキーをハードコーディングしたり、非公開のプライベートフレームワークを使用したりする代わりに、アプリは起動時にIOKitを使用してシステム管理コントローラ (SMC) を動的にプローブします。既知のApple SiliconやIntelのキーを多数チェックし、ホストマシンでアクティブなものを自動的に発見します。
5. **能動的なメモリプレッシャー解放**: 無期限に実行されるバックグラウンドアプリは、多くの場合メモリ断片化に悩まされます。このアプリは、低レベルのメモリ管理関数 (例: `malloc_zone_pressure_relief`) を手動で呼び出し、バックグラウンドのメモリフットプリントを積極的に小さく保つことで、この問題を能動的に軽減しています。

---

## 📄 ライセンス

本プロジェクトは MIT ライセンスの下で公開されています。
