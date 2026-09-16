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

    static func loadProgress() -> Progress {
        guard let data = defaults.data(forKey: progressKey),
              let progress = try? JSONDecoder().decode(Progress.self, from: data) else {
            return Progress()
        }
        return progress
    }

    static func save(_ progress: Progress) {
        if let data = try? JSONEncoder().encode(progress) {
            defaults.set(data, forKey: progressKey)
        }
    }
}
