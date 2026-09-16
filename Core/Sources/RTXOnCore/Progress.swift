import Foundation

/// Player progress; persisted by the app as JSON.
public struct Progress: Codable, Equatable, Sendable {
    public struct Result: Codable, Equatable, Sendable {
        public var pieces: Int
        public var bounces: Int
        public var completedAt: Date

        public init(pieces: Int, bounces: Int, completedAt: Date) {
            self.pieces = pieces
            self.bounces = bounces
            self.completedAt = completedAt
        }
    }

    public var results: [String: Result] = [:]
    /// Day numbers of completed dailies.
    public var dailiesCompleted: Set<Int> = []

    public init() {}

    public func isComplete(_ level: Level) -> Bool {
        results[level.id] != nil
    }

    public func result(for level: Level) -> Result? {
        results[level.id]
    }

    /// Records a solve, keeping the best (fewest pieces, then fewest bounces).
    @discardableResult
    public mutating func record(_ level: Level, pieces: Int, bounces: Int, at date: Date = Date()) -> Bool {
        if level.chapter == .daily { dailiesCompleted.insert(level.index) }
        if let existing = results[level.id], (existing.pieces, existing.bounces) <= (pieces, bounces) {
            return false
        }
        results[level.id] = Result(pieces: pieces, bounces: bounces, completedAt: date)
        return true
    }

    public var campaignCompleted: Int {
        LevelPack.levels.filter(isComplete).count
    }

    public func completed(in chapter: Chapter) -> Int {
        LevelPack.levels(in: chapter).filter(isComplete).count
    }

    /// A chapter unlocks once the previous chapter has at least one solve
    /// (or immediately for the first chapter). Nobody likes a hard gate.
    public func isUnlocked(_ chapter: Chapter) -> Bool {
        guard chapter != .daily, let i = Chapter.campaign.firstIndex(of: chapter), i > 0 else { return true }
        return completed(in: Chapter.campaign[i - 1]) > 0
    }

    /// Consecutive days of dailies ending today (or yesterday, if today is still open).
    public func dailyStreak(today: Int) -> Int {
        var day = dailiesCompleted.contains(today) ? today : today - 1
        var streak = 0
        while day >= 1, dailiesCompleted.contains(day) {
            streak += 1
            day -= 1
        }
        return streak
    }

    /// The first campaign level not yet completed, if any.
    public var nextLevel: Level? {
        LevelPack.levels.first { !isComplete($0) }
    }
}
