import Observation
import RTXOnCore
import SwiftUI
import WidgetKit

@Observable
@MainActor
final class AppState {
    var path: [Route] = []
    private(set) var progress: RTXOnCore.Progress
    /// Injected progress (tests, previews) is never written to disk.
    private let persists: Bool
    var rtxEnabled: Bool {
        didSet { if persists { SharedStore.defaults.set(rtxEnabled, forKey: SharedStore.rtxEnabledKey) } }
    }

    init(progress: RTXOnCore.Progress? = nil) {
        persists = progress == nil
        self.progress = progress ?? SharedStore.loadProgress()
        rtxEnabled = SharedStore.defaults.object(forKey: SharedStore.rtxEnabledKey) as? Bool ?? true
    }

    var today: Int { Daily.dayNumber() }
    var dailyLevel: Level { Daily.level(day: today) }
    var dailySolvedToday: Bool { progress.dailiesCompleted.contains(today) }
    var streak: Int { progress.dailyStreak(today: today) }

    /// Records a solve and refreshes the widget.
    func recordSolve(level: Level, pieces: Int, bounces: Int) {
        progress.record(level, pieces: pieces, bounces: bounces)
        persist()
    }

    func resetProgress() {
        progress = RTXOnCore.Progress()
        persist()
    }

    private func persist() {
        guard persists else { return }
        SharedStore.save(progress)
        WidgetCenter.shared.reloadTimelines(ofKind: SharedStore.widgetKind)
    }

    func open(_ level: Level) {
        path.append(level.chapter == .daily ? .daily(level.index) : .level(level.id))
    }

    /// Replaces the current puzzle with the next one in the campaign.
    func advance(from level: Level) {
        guard let next = LevelPack.next(after: level) else {
            path = []
            return
        }
        if path.last == .level(level.id) { path.removeLast() }
        path.append(.level(next.id))
    }
}
