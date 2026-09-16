import XCTest
@testable import RTXOnCore

final class DailyAndProgressTests: XCTestCase {
    func testSeededGeneratorIsDeterministic() {
        var a = SeededGenerator(seed: 42)
        var b = SeededGenerator(seed: 42)
        for _ in 0..<10 { XCTAssertEqual(a.next(), b.next()) }
        var c = SeededGenerator(seed: 43)
        XCTAssertNotEqual(a.next(), c.next())
    }

    func testDailyLevelsAreDeterministicAndSolvable() {
        for day in 1...120 {
            let level = Daily.level(day: day)
            XCTAssertEqual(level, Daily.level(day: day), "day \(day) differs between calls")
            XCTAssertEqual(level.chapter, .daily)
            XCTAssertEqual(level.index, day)
            XCTAssertTrue(Tracer.trace(level: level, placements: level.solution).solved, "day \(day)")
            XCTAssertFalse(Tracer.trace(level: level, placements: [:]).solved, "day \(day) trivially solved")
            XCTAssertGreaterThanOrEqual(level.inventory.count, 2, "day \(day)")
            XCTAssertEqual(level.width, Daily.width)
            XCTAssertEqual(level.height, Daily.height)
        }
    }

    func testDailyLevelsDifferDayToDay() {
        let ids = Set((1...30).map { Daily.level(day: $0).solution })
        XCTAssertGreaterThan(ids.count, 25)
    }

    func testNoDailyFallsBackForThreeYears() {
        let fallback = Daily.fallbackLevel(day: 1)
        for day in 1...(365 * 3) {
            XCTAssertNotEqual(Daily.level(day: day).solution, fallback.solution, "day \(day) used the fallback")
        }
    }

    func testDayNumber() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let launch = cal.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 12))!
        XCTAssertEqual(Daily.dayNumber(for: launch, calendar: cal), 1)
        let later = cal.date(from: DateComponents(year: 2026, month: 1, day: 31, hour: 3))!
        XCTAssertEqual(Daily.dayNumber(for: later, calendar: cal), 31)
        let before = cal.date(from: DateComponents(year: 2025, month: 6, day: 1))!
        XCTAssertEqual(Daily.dayNumber(for: before, calendar: cal), 1)
    }

    func testProgressRecordsBestResult() {
        var p = Progress()
        let level = LevelPack.levels[0]
        XCTAssertFalse(p.isComplete(level))
        XCTAssertTrue(p.record(level, pieces: 3, bounces: 5))
        XCTAssertTrue(p.isComplete(level))
        XCTAssertFalse(p.record(level, pieces: 3, bounces: 6), "worse result is not recorded")
        XCTAssertTrue(p.record(level, pieces: 2, bounces: 9), "fewer pieces wins")
        XCTAssertEqual(p.result(for: level)?.pieces, 2)
        XCTAssertEqual(p.campaignCompleted, 1)
        XCTAssertEqual(p.nextLevel?.id, "fermi-2")
    }

    func testChapterUnlocking() {
        var p = Progress()
        XCTAssertTrue(p.isUnlocked(.fermi))
        XCTAssertFalse(p.isUnlocked(.kepler))
        XCTAssertTrue(p.isUnlocked(.daily))
        p.record(LevelPack.level(id: "fermi-2")!, pieces: 2, bounces: 2)
        XCTAssertTrue(p.isUnlocked(.kepler))
        XCTAssertFalse(p.isUnlocked(.maxwell))
    }

    func testDailyStreak() {
        var p = Progress()
        XCTAssertEqual(p.dailyStreak(today: 10), 0)
        for day in [7, 8, 9] { p.record(Daily.level(day: day), pieces: 2, bounces: 2) }
        XCTAssertEqual(p.dailyStreak(today: 10), 3, "today still open counts yesterday's run")
        XCTAssertEqual(p.dailyStreak(today: 11), 0)
        p.record(Daily.level(day: 10), pieces: 2, bounces: 2)
        XCTAssertEqual(p.dailyStreak(today: 10), 4)
    }

    func testProgressRoundTripsThroughJSON() throws {
        var p = Progress()
        p.record(LevelPack.levels[0], pieces: 1, bounces: 1, at: Date(timeIntervalSince1970: 1_000))
        p.record(Daily.level(day: 3), pieces: 2, bounces: 2)
        let data = try JSONEncoder().encode(p)
        XCTAssertEqual(try JSONDecoder().decode(Progress.self, from: data), p)
    }

    func testShareCardIsSpoilerFree() throws {
        let level = LevelPack.level(id: "fermi-1")!
        let trace = Tracer.trace(level: level, placements: level.solution)
        let card = ShareCard.text(level: level, placements: level.solution, trace: trace)
        XCTAssertTrue(card.hasPrefix("RTX ON — Fermi 1 · First Light"))
        XCTAssertTrue(card.contains("1 piece (par 1) · 1 bounce"))
        XCTAssertTrue(card.contains("✅"))
        XCTAssertTrue(card.contains("🔆"))
        XCTAssertFalse(card.contains("/"))
        XCTAssertFalse(card.contains("\\"))
        XCTAssertEqual(card.split(separator: "\n").count, 2 + level.height)
    }
}
