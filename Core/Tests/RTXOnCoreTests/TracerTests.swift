import XCTest
@testable import RTXOnCore

final class TracerTests: XCTestCase {
    private func level(_ board: String, _ solution: String = "", colors: [GridPoint: BeamColor] = [:]) throws -> Level {
        let empty = LevelSpec.rows(board).map { String(repeating: ".", count: $0.count) }.joined(separator: "\n")
        return try LevelSpec.parse(id: "t", title: "t", chapter: .fermi, index: 1, board: board,
                                   solution: solution.isEmpty ? empty : solution, colors: colors)
    }

    func testStraightShotLightsTarget() throws {
        let lvl = try level(">...O")
        let r = Tracer.trace(level: lvl, placements: [:])
        XCTAssertTrue(r.solved)
        XCTAssertEqual(r.segments.count, 1)
        XCTAssertEqual(r.segments[0].start, Vec2(0.5, 0.5))
        XCTAssertEqual(r.segments[0].end, Vec2(4.5, 0.5))
        XCTAssertEqual(r.bounces, 0)
    }

    func testWallStopsBeamAtCellEdge() throws {
        let lvl = try level(">.#.O")
        let r = Tracer.trace(level: lvl, placements: [:])
        XCTAssertFalse(r.solved)
        XCTAssertEqual(r.segments[0].end, Vec2(2.0, 0.5))
        XCTAssertTrue(r.litTargets.isEmpty)
    }

    func testBeamLeavesBoardAtEdge() throws {
        let lvl = try level(">....\n....O")
        let r = Tracer.trace(level: lvl, placements: [:])
        XCTAssertEqual(r.segments[0].end, Vec2(5.0, 0.5))
        XCTAssertFalse(r.solved)
    }

    func testMirrorReflections() {
        XCTAssertEqual(Direction.right.reflected(by: .slash), .up)
        XCTAssertEqual(Direction.right.reflected(by: .backslash), .down)
        XCTAssertEqual(Direction.down.reflected(by: .slash), .left)
        XCTAssertEqual(Direction.down.reflected(by: .backslash), .right)
        for d in Direction.allCases {
            for o in MirrorOrientation.allCases {
                // Reflection is an involution.
                XCTAssertEqual(d.reflected(by: o).opposite.reflected(by: o), d.opposite)
            }
        }
    }

    func testPlacedMirrorRoutesBeam() throws {
        let lvl = try level("""
        >....
        .....
        ...O.
        """)
        XCTAssertFalse(Tracer.trace(level: lvl, placements: [:]).solved)
        let r = Tracer.trace(level: lvl, placements: [GridPoint(3, 0): .mirror(.backslash)])
        XCTAssertTrue(r.solved)
        XCTAssertEqual(r.bounces, 1)
        XCTAssertEqual(r.segments.count, 2)
    }

    func testPlacementOnFixedCellIsIgnored() throws {
        let lvl = try level(">.#.O")
        let r = Tracer.trace(level: lvl, placements: [GridPoint(2, 0): .mirror(.slash)])
        XCTAssertFalse(r.solved)
        XCTAssertEqual(r.bounces, 0)
    }

    func testSplitterPassesAndReflects() throws {
        let lvl = try level("""
        ..O..
        >...O
        .....
        """)
        let r = Tracer.trace(level: lvl, placements: [GridPoint(2, 1): .splitter(.slash)])
        XCTAssertTrue(r.solved)
        XCTAssertEqual(r.litTargets.count, 2)
        XCTAssertEqual(r.segments.count, 3)
    }

    func testFilterKeepsSharedComponents() throws {
        let lvl = try level(">...R", colors: [GridPoint(0, 0): .white])
        XCTAssertFalse(Tracer.trace(level: lvl, placements: [:]).solved)
        XCTAssertTrue(Tracer.trace(level: lvl, placements: [:]).mislitTargets.contains(GridPoint(4, 0)))
        let r = Tracer.trace(level: lvl, placements: [GridPoint(2, 0): .filter(.red)])
        XCTAssertTrue(r.solved)
        XCTAssertEqual(r.segments.last?.color, .red)
    }

    func testFilterWithNoSharedComponentKillsBeam() throws {
        let lvl = try level(">...B", colors: [GridPoint(0, 0): .red])
        let r = Tracer.trace(level: lvl, placements: [GridPoint(2, 0): .filter(.blue)])
        XCTAssertEqual(r.segments.count, 1)
        XCTAssertFalse(r.solved)
        XCTAssertTrue(r.mislitTargets.isEmpty)
    }

    func testAdditiveMixing() throws {
        let lvl = try level("""
        >...Y
        ....^
        """, colors: [GridPoint(0, 0): .red])
        let r = Tracer.trace(level: lvl, placements: [:])
        XCTAssertTrue(r.solved)
        XCTAssertEqual(r.targetColors[GridPoint(4, 0)], .yellow)
    }

    func testWrongColorIsMislit() throws {
        let lvl = try level(">...B", colors: [GridPoint(0, 0): .red])
        let r = Tracer.trace(level: lvl, placements: [:])
        XCTAssertFalse(r.solved)
        XCTAssertEqual(r.mislitTargets, [GridPoint(4, 0)])
    }

    func testTargetAbsorbsBeam() throws {
        let lvl = try level(">.O.O")
        let r = Tracer.trace(level: lvl, placements: [:])
        XCTAssertFalse(r.solved)
        XCTAssertEqual(r.litTargets, [GridPoint(2, 0)])
    }

    func testEmitterBlocksBeam() throws {
        let lvl = try level(">.<.O")
        let r = Tracer.trace(level: lvl, placements: [:])
        XCTAssertEqual(r.segments.count, 2)
        XCTAssertFalse(r.solved)
    }

    func testSplitterLoopTerminates() throws {
        let lvl = try level("""
        >....
        .....
        .....
        ....O
        """)
        // Four splitters in a square feed each other forever; the dedupe
        // on (cell, direction, colour) must stop it.
        let r = Tracer.trace(level: lvl, placements: [
            GridPoint(1, 0): .splitter(.backslash),
            GridPoint(3, 0): .splitter(.backslash),
            GridPoint(1, 2): .splitter(.slash),
            GridPoint(3, 2): .splitter(.slash),
        ])
        XCTAssertFalse(r.truncated)
        XCTAssertLessThan(r.segments.count, 40)
    }

    func testFacingMirrorsTerminate() throws {
        let lvl = try level(">....")
        let r = Tracer.trace(level: lvl, placements: [
            GridPoint(2, 0): .mirror(.slash),
        ])
        XCTAssertEqual(r.segments.count, 2)
        XCTAssertFalse(r.truncated)
    }
}
