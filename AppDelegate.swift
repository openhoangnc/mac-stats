import AppKit
import ServiceManagement

public class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var statsView: UnifiedStatsView!
    
    private let statsEngine = StatsEngine()
    private var timer: Timer?
    private var updateInterval: TimeInterval = 2.0
    
    private var currentCpuStats = CPUStats()
    private var currentMemStats = MemoryStats()
    private var currentNetStats = NetworkStats()

    // Periodic heap trim counter (every ~30s at 2s interval = 15 ticks)
    private var ticksSinceLastTrim: Int = 0
    private var trimIntervalTicks: Int = 15

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent app from appearing in Dock or Command-Tab switcher
        NSApp.setActivationPolicy(.accessory)
        
        setupStatusItem()
        startTimer()
        updateStats()
        
        // Purge transient startup heap back to OS after frameworks finish init
        perform(#selector(postStartupTrim), with: nil, afterDelay: 1.0)
    }

    @objc private func postStartupTrim() {
        malloc_zone_pressure_relief(nil, 0)
    }
    
    private func setupStatusItem() {
        let statusBar = NSStatusBar.system
        
        let itemWidth: CGFloat = 74.0
        statusItem = statusBar.statusItem(withLength: itemWidth)
        statsView = UnifiedStatsView(frame: NSRect(x: 0, y: 0, width: itemWidth, height: 22))
        statsView.onClick = { [weak self] in self?.showMenu() }
        statsView.onRightClick = { [weak self] in self?.showMenu() }
        
        if let button = statusItem.button {
            button.addSubview(statsView)
            statsView.frame = button.bounds
            statsView.autoresizingMask = [.width, .height]
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            autoreleasepool {
                self?.updateStats()
            }
        }
        // Allow system to coalesce timer fires for power savings
        timer?.tolerance = updateInterval * 0.25
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func updateStats() {
        currentCpuStats = statsEngine.fetchCPUStats()
        currentMemStats = statsEngine.fetchMemoryStats()
        currentNetStats = statsEngine.fetchNetworkStats()
        
        statsView.updateValues(
            cpuPercent: currentCpuStats.usagePercent,
            memGB: currentMemStats.usedGB,
            memPercent: currentMemStats.usedPercent,
            uploadBytesPerSec: currentNetStats.uploadBytesPerSec,
            downloadBytesPerSec: currentNetStats.downloadBytesPerSec
        )

        // Periodically trim malloc free-lists to reduce fragmentation
        ticksSinceLastTrim += 1
        if ticksSinceLastTrim >= trimIntervalTicks {
            ticksSinceLastTrim = 0
            malloc_zone_pressure_relief(nil, 0)
        }
    }
    
    private func showMenu() {
        let menu = NSMenu()
        
        // --- Settings Section ---
        let autoStartItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        autoStartItem.target = self
        autoStartItem.state = isLaunchAtLoginEnabled ? .on : .off
        menu.addItem(autoStartItem)
        
        let intervalSubmenu = NSMenu()
        let intervals: [(String, TimeInterval)] = [("1 second", 1.0), ("2 seconds", 2.0), ("5 seconds", 5.0)]
        for (label, sec) in intervals {
            let item = NSMenuItem(title: label, action: #selector(changeInterval(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = sec
            item.state = (updateInterval == sec) ? .on : .off
            intervalSubmenu.addItem(item)
        }
        
        let refreshItem = NSMenuItem(title: "Update Interval", action: nil, keyEquivalent: "")
        refreshItem.submenu = intervalSubmenu
        menu.addItem(refreshItem)
        
        menu.addItem(NSMenuItem.separator())

        // GitHub Link
        let githubItem = NSMenuItem(title: "GitHub Repository", action: #selector(openGitHubPage), keyEquivalent: "")
        githubItem.target = self
        menu.addItem(githubItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit MacStats", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }
    
    private var isLaunchAtLoginEnabled: Bool {
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            if status == .enabled { return true }
        }
        
        let plistPath = NSString(string: "~/Library/LaunchAgents/com.openhoangnc.macstats.plist").expandingTildeInPath
        if FileManager.default.fileExists(atPath: plistPath) {
            return true
        }
        
        return UserDefaults.standard.bool(forKey: "LaunchAtLogin")
    }
    
    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let enable = !isLaunchAtLoginEnabled
        setLaunchAtLogin(enabled: enable)
        sender.state = enable ? .on : .off
    }
    
    public static func cleanupLoginItem() {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                    print("--> Unregistered SMAppService mainApp login item.")
                }
            } catch {
                print("--> Failed to unregister SMAppService mainApp: \(error)")
            }
        }
        
        let plistPath = NSString(string: "~/Library/LaunchAgents/com.openhoangnc.macstats.plist").expandingTildeInPath
        let uid = getuid()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["bootout", "gui/\(uid)", plistPath]
        try? process.run()
        process.waitUntilExit()
        
        if FileManager.default.fileExists(atPath: plistPath) {
            try? FileManager.default.removeItem(atPath: plistPath)
            print("--> Removed LaunchAgent plist: \(plistPath)")
        }
        
        UserDefaults.standard.removeObject(forKey: "LaunchAtLogin")
        UserDefaults.standard.synchronize()
    }
    
    private func setLaunchAtLogin(enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "LaunchAtLogin")
        
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                print("SMAppService toggle failed, using LaunchAgent fallback: \(error)")
            }
        }
        
        let plistPath = NSString(string: "~/Library/LaunchAgents/com.openhoangnc.macstats.plist").expandingTildeInPath
        if enabled {
            let execPath = Bundle.main.bundlePath.hasSuffix(".app")
                ? "\(Bundle.main.bundlePath)/Contents/MacOS/MacStats"
                : "/Applications/MacStats.app/Contents/MacOS/MacStats"
            
            let plistContent = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>com.openhoangnc.macstats</string>
                <key>ProgramArguments</key>
                <array>
                    <string>\(execPath)</string>
                </array>
                <key>RunAtLoad</key>
                <true/>
            </dict>
            </plist>
            """
            
            do {
                let launchAgentsDir = NSString(string: "~/Library/LaunchAgents").expandingTildeInPath
                try FileManager.default.createDirectory(atPath: launchAgentsDir, withIntermediateDirectories: true)
                try plistContent.write(toFile: plistPath, atomically: true, encoding: .utf8)
            } catch {
                print("Failed to write LaunchAgent plist: \(error)")
            }
        } else {
            let uid = getuid()
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            process.arguments = ["bootout", "gui/\(uid)", plistPath]
            try? process.run()
            process.waitUntilExit()
            
            if FileManager.default.fileExists(atPath: plistPath) {
                try? FileManager.default.removeItem(atPath: plistPath)
            }
        }
    }
    
    @objc private func changeInterval(_ sender: NSMenuItem) {
        if let sec = sender.representedObject as? TimeInterval {
            updateInterval = sec
            trimIntervalTicks = max(1, Int(30.0 / sec))
            startTimer()
        }
    }
    
    @objc private func openGitHubPage() {
        if let url = URL(string: "https://github.com/openhoangnc/mac-stats") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
