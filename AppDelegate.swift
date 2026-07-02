import AppKit
import ServiceManagement

public class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var statsView: UnifiedStatsView!
    
    private let statsEngine = StatsEngine()
    private var timer: Timer?
    private var updateInterval: TimeInterval = 1.0
    
    private var currentCpuStats = CPUStats()
    private var currentMemStats = MemoryStats()
    private var currentNetStats = NetworkStats()

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent app from appearing in Dock or Command-Tab switcher
        NSApp.setActivationPolicy(.accessory)
        
        setupStatusItem()
        startTimer()
        updateStats()
    }
    
    private func setupStatusItem() {
        let statusBar = NSStatusBar.system
        
        // Single unified status item (width 74px)
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
            self?.updateStats()
        }
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func updateStats() {
        currentCpuStats = statsEngine.fetchCPUStats()
        currentMemStats = statsEngine.fetchMemoryStats()
        currentNetStats = statsEngine.fetchNetworkStats()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.statsView.cpuPercent = self.currentCpuStats.usagePercent
            self.statsView.memGB = self.currentMemStats.usedGB
            self.statsView.memPercent = self.currentMemStats.usedPercent
            
            self.statsView.uploadBytesPerSec = self.currentNetStats.uploadBytesPerSec
            self.statsView.downloadBytesPerSec = self.currentNetStats.downloadBytesPerSec
        }
    }
    
    private func showMenu() {
        let menu = NSMenu()
        
        // Header
        let titleItem = NSMenuItem(title: "MacStats System Monitor", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        if let font = NSFont.boldSystemFont(ofSize: 13) as NSFont? {
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.labelColor]
            titleItem.attributedTitle = NSAttributedString(string: "MacStats System Monitor", attributes: attrs)
        }
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())
        
        // --- CPU Section ---
        let cpuHeader = NSMenuItem(title: String(format: "CPU Utilization: %.1f%%", currentCpuStats.usagePercent), action: nil, keyEquivalent: "")
        cpuHeader.isEnabled = false
        menu.addItem(cpuHeader)
        
        let cpuDetail = NSMenuItem(title: String(format: "  User: %.1f%%  |  Sys: %.1f%%  |  Idle: %.1f%%", currentCpuStats.userPercent, currentCpuStats.systemPercent, currentCpuStats.idlePercent), action: nil, keyEquivalent: "")
        cpuDetail.isEnabled = false
        menu.addItem(cpuDetail)
        
        let cpuCores = NSMenuItem(title: "  Cores: \(currentCpuStats.coreCount) active cores", action: nil, keyEquivalent: "")
        cpuCores.isEnabled = false
        menu.addItem(cpuCores)
        
        menu.addItem(NSMenuItem.separator())
        
        // --- Memory Section ---
        let memHeader = NSMenuItem(title: String(format: "RAM Used: %.2f GB / %.2f GB (%.0f%%)", currentMemStats.usedGB, currentMemStats.totalGB, currentMemStats.usedPercent), action: nil, keyEquivalent: "")
        memHeader.isEnabled = false
        menu.addItem(memHeader)
        
        let memActiveWired = NSMenuItem(title: String(format: "  Active: %.2f GB  |  Wired: %.2f GB", Double(currentMemStats.activeBytes) / 1e9, Double(currentMemStats.wiredBytes) / 1e9), action: nil, keyEquivalent: "")
        memActiveWired.isEnabled = false
        menu.addItem(memActiveWired)
        
        let memCompFree = NSMenuItem(title: String(format: "  Compressed: %.2f GB  |  Free: %.2f GB", Double(currentMemStats.compressedBytes) / 1e9, Double(currentMemStats.freeBytes) / 1e9), action: nil, keyEquivalent: "")
        memCompFree.isEnabled = false
        menu.addItem(memCompFree)
        
        menu.addItem(NSMenuItem.separator())
        
        // --- Network Section ---
        let netHeader = NSMenuItem(title: "Network Interface: \(currentNetStats.activeInterface)", action: nil, keyEquivalent: "")
        netHeader.isEnabled = false
        menu.addItem(netHeader)
        
        let netUp = NSMenuItem(title: String(format: "  Upload Speed: %@ ▲", formatNetSpeed(currentNetStats.uploadBytesPerSec)), action: nil, keyEquivalent: "")
        netUp.isEnabled = false
        menu.addItem(netUp)
        
        let netDown = NSMenuItem(title: String(format: "  Download Speed: %@ ▼", formatNetSpeed(currentNetStats.downloadBytesPerSec)), action: nil, keyEquivalent: "")
        netDown.isEnabled = false
        menu.addItem(netDown)
        
        let netTotals = NSMenuItem(title: String(format: "  Total Sent: %.2f GB  |  Received: %.2f GB", Double(currentNetStats.totalSentBytes) / 1e9, Double(currentNetStats.totalRecvBytes) / 1e9), action: nil, keyEquivalent: "")
        netTotals.isEnabled = false
        menu.addItem(netTotals)
        
        menu.addItem(NSMenuItem.separator())
        
        // --- Settings Section ---
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
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit MacStats", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }
    
    @objc private func changeInterval(_ sender: NSMenuItem) {
        if let sec = sender.representedObject as? TimeInterval {
            updateInterval = sec
            startTimer()
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    private func formatNetSpeed(_ bytesPerSec: Double) -> String {
        if bytesPerSec < 1000 {
            return String(format: "%.0f B", bytesPerSec)
        } else if bytesPerSec < 1000 * 1024 {
            return String(format: "%.1f K", bytesPerSec / 1024.0)
        } else if bytesPerSec < 1000 * 1048576 {
            return String(format: "%.1f M", bytesPerSec / 1048576.0)
        } else {
            return String(format: "%.1f G", bytesPerSec / 1073741824.0)
        }
    }
}
