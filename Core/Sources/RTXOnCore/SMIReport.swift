import Foundation

/// A device snapshot rendered in the shape of `nvidia-smi` output. Every
/// number is real (thermal state, memory, cores, uptime, power mode); the
/// "processes" table is the player's RTX ON progress.
public struct SMIReport: Equatable, Sendable {
    public enum Thermal: String, Sendable {
        case nominal = "Nominal", fair = "Fair", serious = "Serious", critical = "Critical"
    }

    public var deviceName: String
    public var systemVersion: String
    public var thermal: Thermal
    public var memoryUsedBytes: UInt64
    public var memoryTotalBytes: UInt64
    public var cores: Int
    public var uptime: TimeInterval
    public var lowPower: Bool
    public var campaignSolved: Int
    public var campaignTotal: Int
    public var dailyDay: Int
    public var dailySolved: Bool
    public var streak: Int
    public var generatedAt: Date

    public init(deviceName: String, systemVersion: String, thermal: Thermal, memoryUsedBytes: UInt64,
                memoryTotalBytes: UInt64, cores: Int, uptime: TimeInterval, lowPower: Bool,
                campaignSolved: Int, campaignTotal: Int, dailyDay: Int, dailySolved: Bool, streak: Int,
                generatedAt: Date) {
        self.deviceName = deviceName
        self.systemVersion = systemVersion
        self.thermal = thermal
        self.memoryUsedBytes = memoryUsedBytes
        self.memoryTotalBytes = memoryTotalBytes
        self.cores = cores
        self.uptime = uptime
        self.lowPower = lowPower
        self.campaignSolved = campaignSolved
        self.campaignTotal = campaignTotal
        self.dailyDay = dailyDay
        self.dailySolved = dailySolved
        self.streak = streak
        self.generatedAt = generatedAt
    }

    /// nvidia-smi performance states run P0 (max performance) to P12 (idle).
    public var perfState: String { lowPower ? "P8" : "P0" }

    public var memoryUsedMiB: Int { Int(memoryUsedBytes / 1_048_576) }
    public var memoryTotalMiB: Int { Int(memoryTotalBytes / 1_048_576) }
    public var memoryPercent: Int {
        guard memoryTotalBytes > 0 else { return 0 }
        return min(100, Int((Double(memoryUsedBytes) / Double(memoryTotalBytes) * 100).rounded()))
    }

    public var uptimeLabel: String {
        let total = Int(uptime)
        let d = total / 86_400, h = (total % 86_400) / 3_600, m = (total % 3_600) / 60
        return d > 0 ? "\(d)d \(h)h" : "\(h)h \(String(format: "%02d", m))m"
    }

    public var campaignPercent: Int {
        guard campaignTotal > 0 else { return 0 }
        return campaignSolved * 100 / campaignTotal
    }

    /// Table width in characters; every line of `text` is exactly this wide.
    public static let width = 50

    /// The full report, monospaced.
    public var text: String {
        ([SMIReport.timestamp.string(from: generatedAt)] + tableLines).joined(separator: "\n")
    }

    /// Just the boxed tables, without the timestamp header.
    public var tableLines: [String] {
        let w = SMIReport.width
        let inner = w - 2
        let rule = "+" + String(repeating: "-", count: inner) + "+"
        let dbl = "|" + String(repeating: "=", count: inner) + "|"
        func row(_ s: String) -> String { "|" + s.fit(inner) + "|" }
        func cols(_ a: String, _ b: String) -> String { "|" + a.fit(24) + "|" + b.fit(inner - 25) + "|" }
        let sep = "|" + String(repeating: "-", count: 24) + "+" + String(repeating: "-", count: inner - 25) + "|"

        return [
            rule,
            row(" RTX-SMI 1.0.0".fit(18) + "Driver: iOS \(systemVersion)".fit(20) + "Cores: \(cores)"),
            sep,
            cols(" GPU  Name", " Temp      Perf   Pwr"),
            cols("      Memory-Usage", " Uptime    Mem-Util"),
            dbl,
            cols("   0  \(deviceName.fit(16))", " \(thermal.rawValue.fit(10))\(perfState.fit(7))\(lowPower ? "Low" : "Norm")"),
            cols("      \(memoryUsedMiB)MiB / \(memoryTotalMiB)MiB", " \(uptimeLabel.fit(10))\(memoryPercent)%"),
            rule,
            "",
            rule,
            row(" Processes:".fit(inner - 10) + "  GPU-Util"),
            row("  PID  Type  Process name".fit(inner - 10) + "          "),
            dbl,
            row("    1    G   RTX ON campaign \(campaignSolved)/\(campaignTotal)".fit(inner - 6) + "\(campaignPercent)%".leftPadded(4) + "  "),
            row("    2    G   Daily #\(dailyDay) \(dailySolved ? "solved" : "unsolved")".fit(inner - 6) + (dailySolved ? "100%" : "  0%") + "  "),
            row("    3    G   Daily streak \(streak) day\(streak == 1 ? "" : "s")".fit(inner - 6) + "  --" + "  "),
            rule,
        ]
    }

    /// Four lines for small surfaces (medium widget).
    public var compactLines: [String] {
        [
            "RTX-SMI 1.0.0   iOS \(systemVersion)   \(cores) cores",
            "GPU 0  \(deviceName)",
            "\(thermal.rawValue)  \(perfState)  \(memoryUsedMiB)/\(memoryTotalMiB)MiB  \(memoryPercent)%",
            "Campaign \(campaignSolved)/\(campaignTotal) · Daily #\(dailyDay) \(dailySolved ? "✓" : "○") · Streak \(streak)",
        ]
    }

    /// Two lines for the Lock Screen.
    public var lockScreenLines: [String] {
        [
            "\(thermal.rawValue) \(perfState) · \(memoryPercent)% mem",
            "RTX ON \(campaignSolved)/\(campaignTotal) · #\(dailyDay) \(dailySolved ? "✓" : "○") · \(streak)d",
        ]
    }

    public static let timestamp: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE MMM d HH:mm:ss yyyy"
        return f
    }()
}

private extension String {
    /// Pads with spaces or truncates to exactly `width` characters.
    func fit(_ width: Int) -> String {
        if count >= width { return String(prefix(width)) }
        return self + String(repeating: " ", count: width - count)
    }

    func leftPadded(_ width: Int) -> String {
        count >= width ? self : String(repeating: " ", count: width - count) + self
    }
}
