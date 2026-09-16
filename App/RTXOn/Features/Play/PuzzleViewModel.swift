import Observation
import RTXOnCore

/// Board interaction for one level: piece placement, the live trace, undo.
@Observable
@MainActor
final class PuzzleViewModel {
    let level: Level
    private(set) var placements: [GridPoint: Piece] = [:]
    private(set) var trace: TraceResult
    var selectedTool: PieceKind?
    private(set) var hintShown = false
    private(set) var solvedOnce = false
    private var history: [[GridPoint: Piece]] = []

    init(level: Level) {
        self.level = level
        trace = Tracer.trace(level: level, placements: [:])
        selectedTool = level.inventory.first
    }

    var isSolved: Bool { trace.solved }
    var canUndo: Bool { !history.isEmpty }
    var piecesUsed: Int { placements.count }

    /// Distinct kinds in tray order with how many are still available.
    var tray: [(kind: PieceKind, remaining: Int, total: Int)] {
        var seen: [PieceKind] = []
        for k in level.inventory where !seen.contains(k) { seen.append(k) }
        return seen.map { kind in
            let total = level.inventory.filter { $0 == kind }.count
            let used = placements.values.filter { $0.kind == kind }.count
            return (kind, max(0, total - used), total)
        }
    }

    func remaining(_ kind: PieceKind) -> Int {
        tray.first { $0.kind == kind }?.remaining ?? 0
    }

    /// Tap: place the selected tool on an empty cell, rotate an orientable piece,
    /// or remove a piece that has cycled through its orientations.
    func tap(_ p: GridPoint) {
        guard level.isFree(p) else { return }
        if let existing = placements[p] {
            switch existing {
            case .mirror(.slash), .splitter(.slash):
                commit { $0[p] = existing.rotated }
            default:
                commit { $0[p] = nil }
            }
            return
        }
        guard let kind = selectedTool ?? tray.first(where: { $0.remaining > 0 })?.kind,
              remaining(kind) > 0 else { return }
        commit { $0[p] = kind.initialPiece }
        if remaining(kind) == 0, let next = tray.first(where: { $0.remaining > 0 })?.kind {
            selectedTool = next
        } else if remaining(kind) > 0 {
            selectedTool = kind
        }
    }

    func remove(_ p: GridPoint) {
        guard placements[p] != nil else { return }
        commit { $0[p] = nil }
    }

    func undo() {
        guard let previous = history.popLast() else { return }
        placements = previous
        retrace()
    }

    func reset() {
        guard !placements.isEmpty else { return }
        history.append(placements)
        placements = [:]
        retrace()
    }

    func showHint() {
        hintShown = true
    }

    /// Places the reference solution; counts as solved but is flagged in the result.
    func revealSolution() {
        history.append(placements)
        placements = level.solution
        retrace()
    }

    private func commit(_ change: (inout [GridPoint: Piece]) -> Void) {
        history.append(placements)
        change(&placements)
        retrace()
    }

    private func retrace() {
        trace = Tracer.trace(level: level, placements: placements)
        if trace.solved { solvedOnce = true }
    }
}
