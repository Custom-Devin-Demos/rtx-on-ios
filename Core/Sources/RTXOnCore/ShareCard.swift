import Foundation

/// Spoiler-free text summary of a solve, Wordle-style, for pasting into chat.
public enum ShareCard {
    public static func text(level: Level, placements: [GridPoint: Piece], trace: TraceResult) -> String {
        var lines: [String] = []
        lines.append("RTX ON — \(level.displayName)\(level.chapter == .daily ? "" : " · \(level.title)")")
        lines.append("\(placements.count) piece\(placements.count == 1 ? "" : "s") (par \(level.par)) · \(trace.bounces) bounce\(trace.bounces == 1 ? "" : "s")")
        lines.append("")
        for y in 0..<level.height {
            var row = ""
            for x in 0..<level.width {
                row += glyph(at: GridPoint(x, y), level: level, placements: placements, trace: trace)
            }
            lines.append(row)
        }
        return lines.joined(separator: "\n")
    }

    /// Coloured squares for lit cells so the card reads as a beam diagram
    /// without revealing where the optics went.
    static func glyph(at p: GridPoint, level: Level, placements: [GridPoint: Piece], trace: TraceResult) -> String {
        if let piece = level.fixed[p] {
            switch piece {
            case .wall: return "🔲"
            case .emitter: return "🔆"
            case .target:
                if trace.litTargets.contains(p) { return "✅" }
                if trace.mislitTargets.contains(p) { return "❌" }
                return "🎯"
            case .mirror, .splitter, .filter: break
            }
        }
        if trace.pathCells.contains(p) {
            let colors = trace.segments.filter { seg in
                cells(of: seg).contains(p)
            }.reduce(BeamColor()) { $0.union($1.color) }
            return square(for: colors)
        }
        return "⬛"
    }

    static func cells(of seg: BeamSegment) -> [GridPoint] {
        let a = GridPoint(Int(seg.start.x.rounded(.down)), Int(seg.start.y.rounded(.down)))
        let b = GridPoint(Int(seg.end.x.rounded(.down)), Int(seg.end.y.rounded(.down)))
        let xs = min(a.x, b.x)...max(a.x, b.x)
        let ys = min(a.y, b.y)...max(a.y, b.y)
        return xs.flatMap { x in ys.map { GridPoint(x, $0) } }
    }

    static func square(for color: BeamColor) -> String {
        switch color {
        case .red: return "🟥"
        case .green: return "🟩"
        case .blue: return "🟦"
        case .yellow: return "🟨"
        case .magenta: return "🟪"
        case .cyan: return "🟦"
        case .white: return "⬜"
        default: return "🟩"
        }
    }
}
