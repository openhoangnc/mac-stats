import AppKit
import ServiceManagement

public class AppDelegate: NSObject, NSApplicationDelegate {
    private var cpuMemStatusItem: NSStatusItem!
    private var netStatusItem: NSStatusItem!
    
    private var cpuMemView: CPUMemView!
    private var netView: NetworkSpeedView!
    
    private let statsEngine = StatsEngine()
    private var timer: Timer?
    private var updateInterval: TimeInterval = 1.0
    
    private var currentCpuStats = CPUStats()
    private var currentMemStats = MemoryStats()
    private var currentNetStats = NetworkStats()

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent app from appearing in Dock or Command-Tab switcher
        NSApp.setActivationPolicy(.accessory)
        
        setupStatusItems()
        startTimer()
        updateStats()
    }
    
    private func setupStatusItems() {
        let statusBar = NSStatusBar.system
        
        // --- Block 1: CPU & Memory ---
        cpuMemStatusItem = statusBar.statusItem(withLength: 44)
        cpuMemView = CPUMemView(frame: NSRect(x: 0, y: 0, width: 44, height: 22))
        cpuMemView.onClick = { [weak self] in self?.showMenu(for: self?.cpuMemStatusItem) }
        cpuMemView.onRightClick = { [weak self] in self?.showMenu(for: self?.cpuMemStatusItem) }
        if let button = cpuMemStatusItem.button {
            button.addSubview(cpuMemView)
            cpuMemView.frame = button.bounds
            cpuMemView.autoresizingMask = [.width, .height]
        }
        
        // --- Block 2: Network Speed ---
        netStatusItem = statusBar.statusItem(withLength: 56)
        netView = NetworkSpeedView(frame: NSRect(x: 0, y: 0, width: 56, height: 22))
        netView.onClick = { [weak self] in self?.showMenu(for: self?.netStatusItem) }
        netView.onRightClick = { [weak self] in self?.showMenu(for: self?.netStatusItem) }
        if let button = netStatusItem.button {
            button.addSubview(netView)
            netView.frame = button.bounds
            netView.autoresizingMask = [.width, .height]
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
            self.cpuMemView.cpuPercent = self.currentCpuStats.usagePercent
            self.cpuMemView.memGB = self.currentMemStats.usedGB
            
            self.netView.uploadBytesPerSec = self.currentNetStats.uploadBytesPerSec
            self.netView.downloadBytesPerSec = self.currentNetStats.downloadBytesPerSec
        }
    }
    
    private func showMenu(for item: NSStatusItem?) {
        guard let item = item else { return }
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
        
        let netUp = NSMenuItem(title: String(format: "  Upload Speed: ▲ %@", formatNetSpeed(currentNetStats.uploadBytesPerSec)), action: nil, keyEquivalent: "")
        netUp.isEnabled = false
        menu.addItem(netUp)
        
        let netDown = NSMenuItem(title: String(format: "  Download Speed: ▼ %@", formatNetSpeed(currentNetStats.downloadBytesPerSec)), action: nil, keyEquivalent: "")
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
        
        item.menu = menu
        item.button?.performClick(nil)
        item.menu = nil
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
        if bytesPerSec < 1024 {
            return String(format: "%.0f B/s", bytesPerSec)
        } else if bytesPerSec < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytesPerSec / 1024.0)
        } else if bytesPerSec < 1024 * 1024 * 1024 {
            return String(format: "%.2f MB/s", bytesPerSec / (1024.0 * 1024.0))
        } else {
            return String(format: "%.2f GB/s", bytesPerSec / (1024.0 * 1024.0 * 1024.0))
        }
    }
}
