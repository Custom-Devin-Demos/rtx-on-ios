import Foundation
import RTXOnCore

extension SMIReport {
    /// Reads the live device state and the player's progress.
    static func capture(progress: RTXOnCore.Progress, now: Date = Date()) -> SMIReport {
        let info = ProcessInfo.processInfo
        let day = Daily.dayNumber(for: now)
        let v = info.operatingSystemVersion
        return SMIReport(
            deviceName: DeviceIdentity.marketingName,
            systemVersion: v.patchVersion == 0 ? "\(v.majorVersion).\(v.minorVersion)" : "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)",
            thermal: Thermal(info.thermalState),
            memoryUsedBytes: MemoryStats.usedBytes(),
            memoryTotalBytes: info.physicalMemory,
            cores: info.activeProcessorCount,
            uptime: info.systemUptime,
            lowPower: info.isLowPowerModeEnabled,
            campaignSolved: progress.campaignCompleted,
            campaignTotal: LevelPack.levels.count,
            dailyDay: day,
            dailySolved: progress.dailiesCompleted.contains(day),
            streak: progress.dailyStreak(today: day),
            generatedAt: now
        )
    }
}

extension SMIReport.Thermal {
    init(_ state: ProcessInfo.ThermalState) {
        switch state {
        case .nominal: self = .nominal
        case .fair: self = .fair
        case .serious: self = .serious
        case .critical: self = .critical
        @unknown default: self = .nominal
        }
    }
}

enum DeviceIdentity {
    /// Hardware model string, e.g. "iPhone17,1"; on the Simulator, the simulated model.
    static var modelIdentifier: String {
        if let sim = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] { return sim }
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) { String(cString: $0) }
        }
    }

    static var isSimulator: Bool {
        ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] != nil
    }

    static var marketingName: String {
        let id = modelIdentifier
        let name = knownModels[id] ?? id
        return isSimulator ? "\(name) Sim" : name
    }

    static let knownModels: [String: String] = [
        "iPhone14,7": "iPhone 14", "iPhone14,8": "iPhone 14 Plus",
        "iPhone15,2": "iPhone 14 Pro", "iPhone15,3": "iPhone 14 Pro Max",
        "iPhone15,4": "iPhone 15", "iPhone15,5": "iPhone 15 Plus",
        "iPhone16,1": "iPhone 15 Pro", "iPhone16,2": "iPhone 15 Pro Max",
        "iPhone17,1": "iPhone 16 Pro", "iPhone17,2": "iPhone 16 Pro Max",
        "iPhone17,3": "iPhone 16", "iPhone17,4": "iPhone 16 Plus",
        "iPhone17,5": "iPhone 16e",
        "iPhone18,1": "iPhone 17 Pro", "iPhone18,2": "iPhone 17 Pro Max",
        "iPhone18,3": "iPhone 17", "iPhone18,4": "iPhone Air",
    ]
}

enum MemoryStats {
    /// Bytes in use system-wide (active + wired + compressed), via Mach host statistics.
    static func usedBytes() -> UInt64 {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        let pageSize = UInt64(vm_kernel_page_size)
        let used = UInt64(stats.active_count) + UInt64(stats.wire_count) + UInt64(stats.compressor_page_count)
        return used * pageSize
    }
}
