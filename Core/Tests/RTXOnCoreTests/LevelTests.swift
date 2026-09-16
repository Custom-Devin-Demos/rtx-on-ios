import XCTest
@testable import RTXOnCore

final class LevelTests: XCTestCase {
    func testCampaignHasThreeLevelsPerChapter() {
        XCTAssertEqual(LevelPack.levels.count, Chapter.campaign.count * 3)
        for chapter in Chapter.campaign {
            XCTAssertEqual(LevelPack.levels(in: chapter).map(\.index), [1, 2, 3], chapter.name)
        }
        XCTAssertEqual(Set(LevelPack.levels.map(\.id)).count, LevelPack.levels.count, "ids are unique")
    }

    func testEveryLevelIsSolvedByItsSolution() {
        for level in LevelPack.levels {
            let r = Tracer.trace(level: level, placements: level.solution)
            XCTAssertTrue(r.solved, "\(level.id) \(level.title): lit \(r.litTargets.sorted { ($0.y, $0.x) < ($1.y, $1.x) }) of \(level.targets.keys.sorted { ($0.y, $0.x) < ($1.y, $1.x) }) mislit \(r.mislitTargets)")
            XCTAssertFalse(r.truncated, level.id)
        }
    }

    func testNoLevelIsSolvedWithoutPlacingAnything() {
        for level in LevelPack.levels {
            XCTAssertFalse(Tracer.trace(level: level, placements: [:]).solved, level.id)
        }
    }

    func testInventoryMatchesSolution() {
        for level in LevelPack.levels {
            XCTAssertEqual(level.inventory.count, level.solution.count, level.id)
            XCTAssertEqual(Set(level.inventory), Set(level.solution.values.compactMap(\.kind)), level.id)
        }
    }

    func testEveryLevelHasEmittersAndTargets() {
        for level in LevelPack.levels {
            XCTAssertFalse(level.emitters.isEmpty, level.id)
            XCTAssertFalse(level.targets.isEmpty, level.id)
        }
    }

    func testCampaignOrderAndNext() {
        let first = LevelPack.levels[0]
        XCTAssertEqual(first.chapter, .fermi)
        XCTAssertEqual(LevelPack.next(after: first)?.id, "fermi-2")
        XCTAssertEqual(LevelPack.next(after: LevelPack.level(id: "fermi-3")!)?.chapter, .kepler)
        XCTAssertNil(LevelPack.next(after: LevelPack.levels.last!))
    }

    func testParserRejectsRaggedBoard() {
        XCTAssertThrowsError(try LevelSpec.parse(id: "x", title: "x", chapter: .fermi, index: 1,
                                                 board: ">..\n....O", solution: "...\n.....")) { error in
            XCTAssertEqual(error as? LevelSpecError, .ragged("x"))
        }
    }

    func testParserRejectsUnknownGlyph() {
        XCTAssertThrowsError(try LevelSpec.parse(id: "x", title: "x", chapter: .fermi, index: 1,
                                                 board: ">.?.O", solution: ".....")) { error in
            XCTAssertEqual(error as? LevelSpecError, .unknownGlyph("?", GridPoint(2, 0)))
        }
    }

    func testParserRejectsSolutionOnFixedCell() {
        XCTAssertThrowsError(try LevelSpec.parse(id: "x", title: "x", chapter: .fermi, index: 1,
                                                 board: ">.#.O", solution: "../..")) { error in
            XCTAssertEqual(error as? LevelSpecError, .solutionOverlapsFixed(GridPoint(2, 0)))
        }
    }

    func testParserAppliesColorOverrides() throws {
        let level = try LevelSpec.parse(id: "x", title: "x", chapter: .turing, index: 1,
                                        board: ">...R", solution: "..F..",
                                        colors: [GridPoint(0, 0): .white, GridPoint(2, 0): .red])
        XCTAssertEqual(level.fixed[GridPoint(0, 0)], .emitter(.right, .white))
        XCTAssertEqual(level.fixed[GridPoint(4, 0)], .target(.red))
        XCTAssertEqual(level.solution[GridPoint(2, 0)], .filter(.red))
        XCTAssertEqual(level.inventory, [.filter(.red)])
    }

    func testChapterMetadata() {
        XCTAssertEqual(Chapter.campaign.count, 10)
        XCTAssertEqual(Chapter.campaign.first, .fermi)
        XCTAssertEqual(Chapter.campaign.last, .rubin)
        XCTAssertTrue(Chapter.campaign == Chapter.campaign.sorted())
        for c in Chapter.campaign { XCTAssertNotNil(c.year, c.name) }
    }
}
