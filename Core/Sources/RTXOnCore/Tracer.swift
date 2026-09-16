import Foundation

/// One straight run of light, in cell units (see `Vec2`).
public struct BeamSegment: Hashable, Sendable {
    public let start: Vec2
    public let end: Vec2
    public let color: BeamColor
    public let direction: Direction

    public init(start: Vec2, end: Vec2, color: BeamColor, direction: Direction) {
        self.start = start
        self.end = end
        self.color = color
        self.direction = direction
    }
}

public struct TraceResult: Sendable {
    public var segments: [BeamSegment] = []
    /// Accumulated colour delivered to each target cell.
    public var targetColors: [GridPoint: BeamColor] = [:]
    /// Targets whose accumulated colour exactly matches what they require.
    public var litTargets: Set<GridPoint> = []
    /// Targets that received light of the wrong colour.
    public var mislitTargets: Set<GridPoint> = []
    /// Every cell any beam passed through or ended in (not the emitter cells).
    public var pathCells: Set<GridPoint> = []
    public var bounces = 0
    public var solved = false
    /// True when the beam budget was exhausted (e.g. a splitter loop).
    public var truncated = false
}

public enum Tracer {
    /// Upper bound on straight runs per trace; splitter loops are cut off here.
    public static let maxSegments = 512

    public static func trace(level: Level, placements: [GridPoint: Piece]) -> TraceResult {
        var pieces = level.fixed
        for (p, piece) in placements where level.isFree(p) {
            pieces[p] = piece
        }

        struct Beam: Hashable {
            var position: GridPoint
            var direction: Direction
            var color: BeamColor
        }

        var result = TraceResult()
        var queue: [Beam] = level.emitters.map { Beam(position: $0.position, direction: $0.direction, color: $0.color) }
        var seen = Set<Beam>(queue)

        func enqueue(_ beam: Beam) {
            guard !beam.color.isEmpty, seen.insert(beam).inserted else { return }
            queue.append(beam)
        }

        while let beam = queue.popLast() {
            if result.segments.count >= maxSegments {
                result.truncated = true
                break
            }
            var position = beam.position
            let direction = beam.direction
            let color = beam.color
            let start = Vec2.center(of: position)
            var end: Vec2

            runLoop: while true {
                let next = position.moved(direction)
                guard level.contains(next) else {
                    end = Vec2.edge(of: position, facing: direction)
                    break runLoop
                }
                guard let piece = pieces[next] else {
                    position = next
                    result.pathCells.insert(position)
                    continue
                }
                switch piece {
                case .wall, .emitter:
                    end = Vec2.edge(of: position, facing: direction)
                case .target:
                    result.pathCells.insert(next)
                    result.targetColors[next, default: []].formUnion(color)
                    end = Vec2.center(of: next)
                case .mirror(let o):
                    result.pathCells.insert(next)
                    result.bounces += 1
                    enqueue(Beam(position: next, direction: direction.reflected(by: o), color: color))
                    end = Vec2.center(of: next)
                case .splitter(let o):
                    result.pathCells.insert(next)
                    result.bounces += 1
                    enqueue(Beam(position: next, direction: direction, color: color))
                    enqueue(Beam(position: next, direction: direction.reflected(by: o), color: color))
                    end = Vec2.center(of: next)
                case .filter(let f):
                    result.pathCells.insert(next)
                    enqueue(Beam(position: next, direction: direction, color: color.intersection(f)))
                    end = Vec2.center(of: next)
                }
                break runLoop
            }

            result.segments.append(BeamSegment(start: start, end: end, color: color, direction: direction))
        }

        let required = level.targets
        for (p, want) in required {
            let got = result.targetColors[p] ?? []
            if got == want {
                result.litTargets.insert(p)
            } else if !got.isEmpty {
                result.mislitTargets.insert(p)
            }
        }
        result.solved = !required.isEmpty && result.litTargets.count == required.count
        return result
    }
}
