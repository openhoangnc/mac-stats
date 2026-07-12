import Foundation
import MachO
import IOKit

public struct CPUStats {
    public var usagePercent: Double = 0.0
    public var userPercent: Double = 0.0
    public var systemPercent: Double = 0.0
    public var idlePercent: Double = 0.0
    public var coreCount: Int = 0
    public var temperature: Double = 0.0
}

public struct MemoryStats {
    public var usedBytes: UInt64 = 0
    public var totalBytes: UInt64 = 0
    public var activeBytes: UInt64 = 0
    public var wiredBytes: UInt64 = 0
    public var compressedBytes: UInt64 = 0
    public var freeBytes: UInt64 = 0

    public var usedGB: Double {
        return Double(usedBytes) / 1_073_741_824.0
    }
    
    public var totalGB: Double {
        return Double(totalBytes) / 1_073_741_824.0
    }
    
    public var usedPercent: Double {
        return totalBytes > 0 ? (Double(usedBytes) / Double(totalBytes)) * 100.0 : 0.0
    }
}

public struct NetworkStats {
    public var uploadBytesPerSec: Double = 0.0
    public var downloadBytesPerSec: Double = 0.0
    public var totalSentBytes: UInt64 = 0
    public var totalRecvBytes: UInt64 = 0
    public var activeInterface: String = "en0"
}

public struct ProcessUsage {
    public let name: String
    public var cpuPercent: Double
    public var memoryBytes: UInt64
}

public class StatsEngine {
    // Cached immutable system values (queried once)
    private let hostPort: mach_port_t = mach_host_self()
    private let totalPhysicalMemory: UInt64 = ProcessInfo.processInfo.physicalMemory
    private let cachedPageSize: UInt64
    
    // CPU delta tracking
    private var prevCpuInfo: processor_info_array_t?
    private var prevCpuInfoCount: mach_msg_type_number_t = 0
    
    // Network delta tracking
    private var prevNetBytesSent: UInt64 = 0
    private var prevNetBytesRecv: UInt64 = 0
    private var prevNetTime: CFAbsoluteTime = 0
    private var cachedActiveInterface: String = "en0"
    
    // Active temperature keys cached after startup scan
    private var activeTempKeys: [String] = []

    public init() {
        var pageSize: vm_size_t = 4096
        host_page_size(hostPort, &pageSize)
        cachedPageSize = UInt64(pageSize)
        
        self.activeTempKeys = scanActiveTempKeys()
    }
    
    private func scanActiveTempKeys() -> [String] {
        let smc = SMC.shared
        func isActive(_ key: String) -> Bool {
            guard let val = smc.getValue(key) else { return false }
            return val > 15.0 && val < 110.0
        }

        // Apple Silicon per-core / cluster sensors, averaged together.
        let appleSiliconKeys = [
            // Base/General M1/M2/M3/M4/M5 CPU keys
            "Tc0a", "Tc0b", "Tc0x", "Tc0z",
            "Tc1a", "Tc1b", "Tc1x", "Tc1z",
            "Tc2a", "Tc2b", "Tc2x", "Tc2z",
            "Tc3a", "Tc3b", "Tc3x", "Tc3z",
            "Tc4a", "Tc4b", "Tc4x", "Tc4z",
            "Tc5a", "Tc5b", "Tc5x", "Tc5z",
            "Tc6a", "Tc6b", "Tc6x", "Tc6z",
            "Tc7a", "Tc7b", "Tc7x", "Tc7z",
            "Tc8a", "Tc8b", "Tc8x", "Tc8z",
            "Tc9a", "Tc9b", "Tc9x", "Tc9z",
            "Tcaa", "Tcab", "Tcax", "Tcaz",
            
            // M3/M4/M5 Efficiency cores
            "Te05", "Te0L", "Te0P", "Te0S", "Te09", "Te0H", "Te0a", "Te0b", "Te0x", "Te0z",
            "Te3a", "Te3b", "Te3x", "Te3z",
            
            // M3/M4 Performance cores
            "Tf04", "Tf09", "Tf0A", "Tf0B", "Tf0D", "Tf0E", "Tf44", "Tf49", "Tf4A", "Tf4B", "Tf4D", "Tf4E",
            
            // M1/M2 Pro/Max/Ultra and general Tp keys
            "Tp01", "Tp05", "Tp09", "Tp0D", "Tp0H", "Tp0L", "Tp0P", "Tp0X", "Tp0b", "Tp0e", "Tp0T", "Tp0V", "Tp0Y",
            "Tp1h", "Tp1t", "Tp1p", "Tp1l",
            "Tp2a", "Tp2b", "Tp2x", "Tp2z",
            "Tp3a", "Tp3b", "Tp3x", "Tp3z",
            "Tp4a", "Tp4b", "Tp4x", "Tp4z",
            "Tp5a", "Tp5b", "Tp5x", "Tp5z",
            "Tp7a", "Tp7b", "Tp7x", "Tp7z",
            "Tp8a", "Tp8b", "Tp8x", "Tp8z",
            "Tp9a", "Tp9b", "Tp9x", "Tp9z"
        ]
        
        let appleSiliconActive = appleSiliconKeys.filter(isActive)
        if !appleSiliconActive.isEmpty { return appleSiliconActive }

        // --- Intel Macs ---
        // Prefer the per-core die sensors, averaged together (mirrors the
        // Apple Silicon path above). Both upper- and lower-case suffixes
        // appear depending on the model; only one set is ever active.
        let intelCoreKeys = [
            "TC0C", "TC1C", "TC2C", "TC3C", "TC4C", "TC5C", "TC6C", "TC7C", "TC8C", "TC9C",
            "TC0c", "TC1c", "TC2c", "TC3c", "TC4c", "TC5c", "TC6c", "TC7c", "TC8c", "TC9c"
        ]
        let intelCoreActive = intelCoreKeys.filter(isActive)
        if !intelCoreActive.isEmpty { return intelCoreActive }

        // Fall back to a single summary sensor, in order of preference:
        // on-die diode, package, proximity, then heatsink.
        let intelFallbackKeys = ["TC0D", "TC0E", "TC0F", "TCAD", "TC0P", "TC0H"]
        if let key = intelFallbackKeys.first(where: isActive) {
            return [key]
        }
        return []
    }

    deinit {
        if let prevCpuInfo = prevCpuInfo {
            let prevSize = MemoryLayout<integer_t>.size * Int(prevCpuInfoCount)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: prevCpuInfo), vm_size_t(prevSize))
        }
    }

    // MARK: - CPU Sampling
    public func fetchCPUStats() -> CPUStats {
        var stats = CPUStats()
        var numCPUs: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var cpuInfoCount: mach_msg_type_number_t = 0
        
        let result = host_processor_info(hostPort, PROCESSOR_CPU_LOAD_INFO, &numCPUs, &cpuInfo, &cpuInfoCount)
        guard result == KERN_SUCCESS, let cpuInfo = cpuInfo else {
            return stats
        }
        
        stats.coreCount = Int(numCPUs)
        
        if let prevCpuInfo = prevCpuInfo {
            var totalUser: UInt64 = 0
            var totalSystem: UInt64 = 0
            var totalIdle: UInt64 = 0
            var totalNice: UInt64 = 0
            var totalTicks: UInt64 = 0
            
            for i in 0..<Int(numCPUs) {
                let offset = Int(CPU_STATE_MAX) * i
                
                let userDelta = UInt64(cpuInfo[offset + Int(CPU_STATE_USER)] - prevCpuInfo[offset + Int(CPU_STATE_USER)])
                let systemDelta = UInt64(cpuInfo[offset + Int(CPU_STATE_SYSTEM)] - prevCpuInfo[offset + Int(CPU_STATE_SYSTEM)])
                let idleDelta = UInt64(cpuInfo[offset + Int(CPU_STATE_IDLE)] - prevCpuInfo[offset + Int(CPU_STATE_IDLE)])
                let niceDelta = UInt64(cpuInfo[offset + Int(CPU_STATE_NICE)] - prevCpuInfo[offset + Int(CPU_STATE_NICE)])
                
                totalUser += userDelta
                totalSystem += systemDelta
                totalIdle += idleDelta
                totalNice += niceDelta
                totalTicks += (userDelta + systemDelta + idleDelta + niceDelta)
            }
            
            if totalTicks > 0 {
                let totalActive = totalUser + totalSystem + totalNice
                stats.usagePercent = (Double(totalActive) / Double(totalTicks)) * 100.0
                stats.userPercent = (Double(totalUser) / Double(totalTicks)) * 100.0
                stats.systemPercent = (Double(totalSystem) / Double(totalTicks)) * 100.0
                stats.idlePercent = (Double(totalIdle) / Double(totalTicks)) * 100.0
            }
            
            let prevSize = MemoryLayout<integer_t>.size * Int(prevCpuInfoCount)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: prevCpuInfo), vm_size_t(prevSize))
        }
        
        self.prevCpuInfo = cpuInfo
        self.prevCpuInfoCount = cpuInfoCount
        
        // Calculate CPU average temperature
        if !activeTempKeys.isEmpty {
            var sum: Double = 0.0
            var count = 0
            let smc = SMC.shared
            for key in activeTempKeys {
                if let val = smc.getValue(key), val > 15.0 && val < 110.0 {
                    sum += val
                    count += 1
                }
            }
            if count > 0 {
                stats.temperature = sum / Double(count)
            }
        }
        
        return stats
    }

    // MARK: - Memory Sampling
    public func fetchMemoryStats() -> MemoryStats {
        var stats = MemoryStats()
        stats.totalBytes = totalPhysicalMemory
        
        var stats64 = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        
        let kerr = withUnsafeMutablePointer(to: &stats64) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard kerr == KERN_SUCCESS else {
            return stats
        }
        
        let page = cachedPageSize
        let active = UInt64(stats64.active_count) * page
        let wired = UInt64(stats64.wire_count) * page
        let compressed = UInt64(stats64.compressor_page_count) * page
        let free = UInt64(stats64.free_count) * page
        
        stats.activeBytes = active
        stats.wiredBytes = wired
        stats.compressedBytes = compressed
        stats.freeBytes = free
        stats.usedBytes = active + wired + compressed
        
        return stats
    }

    // MARK: - Network Sampling
    public func fetchNetworkStats() -> NetworkStats {
        var stats = NetworkStats()
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return stats
        }
        defer { freeifaddrs(ifaddr) }
        
        var currentBytesSent: UInt64 = 0
        var currentBytesRecv: UInt64 = 0
        var foundEnInterface = false
        
        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let curr = ptr {
            let flags = Int32(curr.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) != 0
            let isRunning = (flags & IFF_RUNNING) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0
            
            if isUp && isRunning && !isLoopback {
                if curr.pointee.ifa_addr.pointee.sa_family == UInt8(AF_LINK) {
                    if let namePtr = curr.pointee.ifa_name {
                        // Zero-alloc check: compare raw bytes for "en" prefix (0x65='e', 0x6e='n')
                        if namePtr.pointee == 0x65 && namePtr.advanced(by: 1).pointee == 0x6e {
                            if let data = curr.pointee.ifa_data {
                                let ifData = data.assumingMemoryBound(to: if_data.self)
                                currentBytesRecv += UInt64(ifData.pointee.ifi_ibytes)
                                currentBytesSent += UInt64(ifData.pointee.ifi_obytes)
                                
                                if !foundEnInterface {
                                    foundEnInterface = true
                                    let nameStr = String(cString: namePtr)
                                    if nameStr != cachedActiveInterface {
                                        cachedActiveInterface = nameStr
                                    }
                                }
                            }
                        }
                    }
                }
            }
            ptr = curr.pointee.ifa_next
        }
        
        stats.totalSentBytes = currentBytesSent
        stats.totalRecvBytes = currentBytesRecv
        stats.activeInterface = cachedActiveInterface
        
        let now = CFAbsoluteTimeGetCurrent()
        if prevNetTime > 0 {
            let dt = now - prevNetTime
            if dt > 0 {
                let sentDelta = currentBytesSent >= prevNetBytesSent ? currentBytesSent - prevNetBytesSent : 0
                let recvDelta = currentBytesRecv >= prevNetBytesRecv ? currentBytesRecv - prevNetBytesRecv : 0
                
                stats.uploadBytesPerSec = Double(sentDelta) / dt
                stats.downloadBytesPerSec = Double(recvDelta) / dt
            }
        }
        
        self.prevNetBytesSent = currentBytesSent
        self.prevNetBytesRecv = currentBytesRecv
        self.prevNetTime = now

        return stats
    }

    // MARK: - Per-Process Sampling
    /// Returns per-application resource usage, ranked by CPU and by memory.
    /// Only the current user's processes are included, which naturally
    /// excludes root/system daemons (kernel_task, WindowServer, mds, …).
    /// Helper processes are rolled up into their parent `.app` bundle so a
    /// browser's many renderers appear as a single application.
    ///
    /// `ps` reports an instantaneous %CPU (the kernel's decaying average), so
    /// no second sample is needed. This is only called on menu open, so the
    /// one-off subprocess cost never touches the periodic update path.
    public func fetchTopProcesses(limit: Int) -> (byCPU: [ProcessUsage], byMemory: [ProcessUsage]) {
        let currentUID = getuid()

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        // -a: all users  -x: include processes with no controlling tty (GUI apps).
        // `comm` (full executable path) must be last since it can contain spaces.
        task.arguments = ["-axo", "pcpu=,rss=,uid=,comm="]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        guard (try? task.run()) != nil else { return ([], []) }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        guard let output = String(data: data, encoding: .utf8) else { return ([], []) }

        // Exclude our own app from the ranking.
        let selfName = Bundle.main.infoDictionary?["CFBundleName"] as? String

        var byName: [String: ProcessUsage] = [:]
        for line in output.split(separator: "\n") {
            guard let (cpu, rssKB, uid, comm) = Self.parseProcessLine(line) else { continue }
            guard uid == currentUID else { continue }
            let name = Self.appName(fromPath: comm)
            guard !name.isEmpty, name != selfName else { continue }

            if byName[name] != nil {
                byName[name]!.cpuPercent += cpu
                byName[name]!.memoryBytes += rssKB * 1024
            } else {
                byName[name] = ProcessUsage(name: name, cpuPercent: cpu, memoryBytes: rssKB * 1024)
            }
        }

        let all = Array(byName.values)
        let byCPU = all.sorted { $0.cpuPercent > $1.cpuPercent }.prefix(limit)
        let byMemory = all.sorted { $0.memoryBytes > $1.memoryBytes }.prefix(limit)
        return (Array(byCPU), Array(byMemory))
    }

    /// Parses one `ps` line: three leading numeric columns (pcpu, rss, uid)
    /// followed by the command path, which may itself contain spaces.
    private static func parseProcessLine(_ line: Substring) -> (cpu: Double, rssKB: UInt64, uid: uid_t, comm: String)? {
        var idx = line.startIndex
        func skipSpaces() { while idx < line.endIndex, line[idx] == " " { idx = line.index(after: idx) } }
        func nextToken() -> Substring? {
            skipSpaces()
            guard idx < line.endIndex else { return nil }
            let start = idx
            while idx < line.endIndex, line[idx] != " " { idx = line.index(after: idx) }
            return line[start..<idx]
        }

        guard let t1 = nextToken(), let cpu = Double(t1),
              let t2 = nextToken(), let rss = UInt64(t2),
              let t3 = nextToken(), let uid = UInt32(t3) else { return nil }
        skipSpaces()
        guard idx < line.endIndex else { return nil }
        return (cpu, rss, uid_t(uid), String(line[idx...]))
    }

    /// Derives a friendly application name from an executable path. Prefers the
    /// top-level `.app` bundle name (so helpers roll up into their parent app);
    /// otherwise falls back to the executable's file name.
    private static func appName(fromPath path: String) -> String {
        let components = path.split(separator: "/", omittingEmptySubsequences: true)
        for comp in components where comp.hasSuffix(".app") {
            return String(comp.dropLast(4))
        }
        return components.last.map(String.init) ?? ""
    }
}
