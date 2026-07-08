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
        
        let initialWidth = UnifiedStatsView.calculateWidth(showNetwork: showNetworkSpeeds, showTemperature: showCPUTemperature)
        statusItem = statusBar.statusItem(withLength: initialWidth)
        statsView = UnifiedStatsView(frame: NSRect(x: 0, y: 0, width: initialWidth, height: 22))
        statsView.onClick = { [weak self] in self?.showMenu() }
        statsView.onRightClick = { [weak self] in self?.showMenu() }
        
        statsView.showNetwork = showNetworkSpeeds
        statsView.showTemperature = showCPUTemperature
        updateStatusItemWidth()
        
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
            cpuTemperature: currentCpuStats.temperature,
            tempUnit: tempUnit,
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
        // Manage item enabled-state ourselves so info rows stay legible (not greyed).
        menu.autoenablesItems = false

        // --- Top Processes Section ---
        // Fetched fresh on open; excludes system daemons and rolls helpers into their app.
        // Rows start as plain items so the menu can compute its natural width; below
        // we swap in width-filling views that right-align the value flush to that width.
        var usageRows: [(item: NSMenuItem, name: String, value: String)] = []
        let top = statsEngine.fetchTopProcesses(limit: 3)
        if !top.byCPU.isEmpty {
            menu.addItem(Self.sectionHeader("Top CPU"))
            for p in top.byCPU {
                let value = Self.formatCPU(p.cpuPercent)
                let item = Self.provisionalUsageItem(name: p.name, value: value)
                menu.addItem(item)
                usageRows.append((item, p.name, value))
            }
            menu.addItem(NSMenuItem.separator())
        }
        if !top.byMemory.isEmpty {
            menu.addItem(Self.sectionHeader("Top Memory"))
            for p in top.byMemory {
                let value = Self.formatMemory(p.memoryBytes)
                let item = Self.provisionalUsageItem(name: p.name, value: value)
                menu.addItem(item)
                usageRows.append((item, p.name, value))
            }
            menu.addItem(NSMenuItem.separator())
        }

        // Jump to Activity Monitor for the full, detailed breakdown.
        let activityItem = NSMenuItem(title: "Open Activity Monitor", action: #selector(openActivityMonitor), keyEquivalent: "")
        activityItem.target = self
        menu.addItem(activityItem)
        menu.addItem(NSMenuItem.separator())

        // --- Settings Section ---
        let showNetItem = NSMenuItem(title: "Show Network Speeds", action: #selector(toggleShowNetwork(_:)), keyEquivalent: "")
        showNetItem.target = self
        showNetItem.state = showNetworkSpeeds ? .on : .off
        menu.addItem(showNetItem)
        
        let showTempItem = NSMenuItem(title: "Show CPU Temperature", action: #selector(toggleShowTemperature(_:)), keyEquivalent: "")
        showTempItem.target = self
        showTempItem.state = showCPUTemperature ? .on : .off
        menu.addItem(showTempItem)
        
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
        
        let tempUnitSubmenu = NSMenu()
        let tempUnits = [("Celsius (°C)", "C"), ("Fahrenheit (°F)", "F")]
        for (label, key) in tempUnits {
            let item = NSMenuItem(title: label, action: #selector(changeTempUnit(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = key
            item.state = (tempUnit == key) ? .on : .off
            tempUnitSubmenu.addItem(item)
        }
        
        let tempUnitItem = NSMenuItem(title: "Temperature Unit", action: nil, keyEquivalent: "")
        tempUnitItem.submenu = tempUnitSubmenu
        menu.addItem(tempUnitItem)
        
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
        
        // Now that every item is present, the menu's width is final. Replace each
        // provisional process row with a view that fills that width and pins its
        // value to the right edge — so the value column aligns with no trailing gap.
        if !usageRows.isEmpty {
            let width = menu.size.width
            for row in usageRows {
                row.item.title = ""
                row.item.view = Self.usageRowView(name: row.name, value: row.value, width: width)
            }
        }

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
    
    private var tempUnit: String {
        get {
            return UserDefaults.standard.string(forKey: "tempUnit") ?? "C"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "tempUnit")
            updateStats()
        }
    }
    
    private var showNetworkSpeeds: Bool {
        get { UserDefaults.standard.object(forKey: "showNetworkSpeeds") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "showNetworkSpeeds"); updateUIForSettingsChange() }
    }
    
    private var showCPUTemperature: Bool {
        get { UserDefaults.standard.object(forKey: "showCPUTemperature") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "showCPUTemperature"); updateUIForSettingsChange() }
    }
    
    @objc private func toggleShowNetwork(_ sender: NSMenuItem) {
        showNetworkSpeeds.toggle()
    }
    
    @objc private func toggleShowTemperature(_ sender: NSMenuItem) {
        showCPUTemperature.toggle()
    }
    
    private func updateUIForSettingsChange() {
        statsView.showNetwork = showNetworkSpeeds
        statsView.showTemperature = showCPUTemperature
        updateStatusItemWidth()
        statsView.needsDisplay = true
    }

    private func updateStatusItemWidth() {
        let width = UnifiedStatsView.calculateWidth(showNetwork: showNetworkSpeeds, showTemperature: showCPUTemperature)
        statusItem.length = width
        statsView.frame.size.width = width
    }
    
    @objc private func changeTempUnit(_ sender: NSMenuItem) {
        if let unit = sender.representedObject as? String {
            tempUnit = unit
        }
    }
    
    @objc private func openGitHubPage() {
        if let url = URL(string: "https://github.com/openhoangnc/mac-stats") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func openActivityMonitor() {
        let workspace = NSWorkspace.shared
        if let url = workspace.urlForApplication(withBundleIdentifier: "com.apple.ActivityMonitor") {
            workspace.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        } else {
            // Fallback to the canonical location on macOS 11+.
            workspace.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Top Processes menu rendering

    private static func sectionHeader(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        item.attributedTitle = NSAttributedString(string: title, attributes: [
            .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold),
            .foregroundColor: NSColor.secondaryLabelColor
        ])
        return item
    }

    /// A placeholder row used only so the menu can size itself to fit the widest
    /// "name  value" pair before we swap in the final width-filling view.
    private static func provisionalUsageItem(name: String, value: String) -> NSMenuItem {
        let display = name.count > 28 ? String(name.prefix(27)) + "…" : name
        let item = NSMenuItem(title: "\(display)    \(value)", action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    /// A non-interactive row that fills the menu's full `width`: app name on the
    /// left (truncated to fit), value flush to the right edge. Filling the width
    /// is what removes the trailing empty space a fixed tab stop would leave.
    private static func usageRowView(name: String, value: String, width: CGFloat) -> NSView {
        let leftInset: CGFloat = 21
        let rightInset: CGFloat = 21
        let font = NSFont.menuFont(ofSize: 0)
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: 20))

        let valueWidth = NSAttributedString(string: value, attributes: [.font: font]).size().width
        let valueLabel = NSTextField(labelWithString: value)
        valueLabel.font = font
        valueLabel.textColor = .secondaryLabelColor
        valueLabel.alignment = .right
        valueLabel.frame = NSRect(x: width - rightInset - valueWidth, y: 2, width: valueWidth + 1, height: 16)
        valueLabel.autoresizingMask = [.minXMargin]
        container.addSubview(valueLabel)

        let nameLabel = NSTextField(labelWithString: name)
        nameLabel.font = font
        nameLabel.textColor = .labelColor
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.maximumNumberOfLines = 1
        nameLabel.frame = NSRect(x: leftInset, y: 2,
                                 width: max(0, valueLabel.frame.minX - 8 - leftInset), height: 16)
        nameLabel.autoresizingMask = [.width]
        container.addSubview(nameLabel)

        return container
    }

    private static func formatCPU(_ percent: Double) -> String {
        return String(format: "%.0f%%", percent)
    }

    private static func formatMemory(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824.0
        if gb >= 1.0 { return String(format: "%.1f GB", gb) }
        return String(format: "%.0f MB", Double(bytes) / 1_048_576.0)
    }
}
