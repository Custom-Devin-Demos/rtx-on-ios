import RTXOnCore
import XCTest
@testable import RTXOn

@MainActor
final class PuzzleViewModelTests: XCTestCase {
    private var level: Level { LevelPack.level(id: "fermi-1")! }

    func testTapPlacesRotatesThenRemoves() {
        let vm = PuzzleViewModel(level: level)
        let cell = GridPoint(3, 2)
        XCTAssertEqual(vm.selectedTool, .mirror)
        vm.tap(cell)
        XCTAssertEqual(vm.placements[cell], .mirror(.slash))
        XCTAssertEqual(vm.remaining(.mirror), 0)
        vm.tap(cell)
        XCTAssertEqual(vm.placements[cell], .mirror(.backslash))
        XCTAssertTrue(vm.isSolved, "fermi-1 is solved by a backslash at (3,2)")
        vm.tap(cell)
        XCTAssertNil(vm.placements[cell])
        XCTAssertFalse(vm.isSolved)
        XCTAssertEqual(vm.remaining(.mirror), 1)
    }

    func testCannotExceedInventory() {
        let vm = PuzzleViewModel(level: level)
        vm.tap(GridPoint(1, 1))
        vm.tap(GridPoint(2, 2))
        XCTAssertEqual(vm.piecesUsed, 1)
    }

    func testFixedCellsIgnoreTaps() {
        let vm = PuzzleViewModel(level: level)
        vm.tap(GridPoint(0, 2)) // emitter
        XCTAssertEqual(vm.piecesUsed, 0)
        XCTAssertFalse(vm.canUndo)
    }

    func testUndoAndReset() {
        let vm = PuzzleViewModel(level: level)
        vm.tap(GridPoint(1, 1))
        XCTAssertTrue(vm.canUndo)
        vm.undo()
        XCTAssertEqual(vm.piecesUsed, 0)
        vm.tap(GridPoint(1, 1))
        vm.reset()
        XCTAssertEqual(vm.piecesUsed, 0)
        vm.undo()
        XCTAssertEqual(vm.piecesUsed, 1)
    }

    func testRevealSolutionSolves() {
        let vm = PuzzleViewModel(level: level)
        vm.revealSolution()
        XCTAssertTrue(vm.isSolved)
    }

    func testAppStateRecordsAndAdvances() {
        let state = AppState(progress: RTXOnCore.Progress())
        state.path = [.level("fermi-1")]
        state.recordSolve(level: level, pieces: 1, bounces: 1)
        XCTAssertTrue(state.progress.isComplete(level))
        state.advance(from: level)
        XCTAssertEqual(state.path, [.level("fermi-2")])
    }
}
