import Foundation
import MachO
import IOKit

public struct CPUStats {
    public var usagePercent: Double = 0.0
    public var userPercent: Double = 0.0
    public var systemPercent: Double = 0.0
    public var idlePercent: Double = 0.0
    public var coreCount: Int = ProcessInfo.processInfo.activeProcessorCount
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

public class StatsEngine {
    private var prevCpuInfo: processor_info_array_t?
    private var prevCpuInfoCount: mach_msg_type_number_t = 0
    
    private var prevNetBytesSent: UInt64 = 0
    private var prevNetBytesRecv: UInt64 = 0
    private var prevNetTime: Date?

    public init() {}

    // MARK: - CPU Sampling
    public func fetchCPUStats() -> CPUStats {
        var stats = CPUStats()
        var numCPUs: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var cpuInfoCount: mach_msg_type_number_t = 0
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUs, &cpuInfo, &cpuInfoCount)
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
        return stats
    }

    // MARK: - Memory Sampling
    public func fetchMemoryStats() -> MemoryStats {
        var stats = MemoryStats()
        stats.totalBytes = ProcessInfo.processInfo.physicalMemory
        
        var stats64 = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        
        let kerr = withUnsafeMutablePointer(to: &stats64) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard kerr == KERN_SUCCESS else {
            return stats
        }
        
        var pageSize: vm_size_t = 4096
        host_page_size(mach_host_self(), &pageSize)
        let page = UInt64(pageSize)
        
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
        var primaryInterface = "en0"
        
        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let curr = ptr {
            let flags = Int32(curr.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) != 0
            let isRunning = (flags & IFF_RUNNING) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0
            
            if isUp && isRunning && !isLoopback {
                let name = String(cString: curr.pointee.ifa_name)
                if curr.pointee.ifa_addr.pointee.sa_family == UInt8(AF_LINK) {
                    if let data = curr.pointee.ifa_data {
                        let ifData = data.assumingMemoryBound(to: if_data.self)
                        let bytesRecv = UInt64(ifData.pointee.ifi_ibytes)
                        let bytesSent = UInt64(ifData.pointee.ifi_obytes)
                        
                        // Prefer physical interfaces starting with 'en'
                        if name.hasPrefix("en") {
                            primaryInterface = name
                            currentBytesRecv += bytesRecv
                            currentBytesSent += bytesSent
                        }
                    }
                }
            }
            ptr = curr.pointee.ifa_next
        }
        
        stats.totalSentBytes = currentBytesSent
        stats.totalRecvBytes = currentBytesRecv
        stats.activeInterface = primaryInterface
        
        let now = Date()
        if let prevTime = prevNetTime {
            let dt = now.timeIntervalSince(prevTime)
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
}
