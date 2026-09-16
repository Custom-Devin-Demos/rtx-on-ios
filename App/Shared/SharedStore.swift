import Foundation
import RTXOnCore

/// Progress lives in the App Group so the widget can read it.
enum SharedStore {
    static let appGroup = "group.com.devindemos.nvidia.rtxon"
    static let progressKey = "rtxon.progress.v1"
    static let rtxEnabledKey = "rtxon.rtxEnabled"
    static let widgetKind = "RTXOnSMIWidget"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static func loadProgress() -> RTXOnCore.Progress {
        guard let data = defaults.data(forKey: progressKey),
              let progress = try? JSONDecoder().decode(RTXOnCore.Progress.self, from: data) else {
            return RTXOnCore.Progress()
        }
        return progress
    }

    static func save(_ progress: RTXOnCore.Progress) {
        if let data = try? JSONEncoder().encode(progress) {
            defaults.set(data, forKey: progressKey)
        }
    }
}
