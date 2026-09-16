import Foundation

/// Campaign chapters are named after NVIDIA GPU architectures, oldest first.
public enum Chapter: Int, CaseIterable, Codable, Sendable, Comparable {
    case fermi = 1, kepler, maxwell, pascal, volta, turing, ampere, hopper, blackwell, rubin
    case daily = 100

    public static let campaign: [Chapter] = Chapter.allCases.filter { $0 != .daily }

    public static func < (lhs: Chapter, rhs: Chapter) -> Bool { lhs.rawValue < rhs.rawValue }

    public var name: String {
        switch self {
        case .fermi: return "Fermi"
        case .kepler: return "Kepler"
        case .maxwell: return "Maxwell"
        case .pascal: return "Pascal"
        case .volta: return "Volta"
        case .turing: return "Turing"
        case .ampere: return "Ampere"
        case .hopper: return "Hopper"
        case .blackwell: return "Blackwell"
        case .rubin: return "Rubin"
        case .daily: return "Daily"
        }
    }

    public var year: Int? {
        switch self {
        case .fermi: return 2010
        case .kepler: return 2012
        case .maxwell: return 2014
        case .pascal: return 2016
        case .volta: return 2017
        case .turing: return 2018
        case .ampere: return 2020
        case .hopper: return 2022
        case .blackwell: return 2024
        case .rubin: return 2026
        case .daily: return nil
        }
    }

    public var namesake: String {
        switch self {
        case .fermi: return "Enrico Fermi"
        case .kepler: return "Johannes Kepler"
        case .maxwell: return "James Clerk Maxwell"
        case .pascal: return "Blaise Pascal"
        case .volta: return "Alessandro Volta"
        case .turing: return "Alan Turing"
        case .ampere: return "André-Marie Ampère"
        case .hopper: return "Grace Hopper"
        case .blackwell: return "David Blackwell"
        case .rubin: return "Vera Rubin"
        case .daily: return "One puzzle a day"
        }
    }

    /// The mechanic each chapter introduces.
    public var mechanic: String {
        switch self {
        case .fermi: return "Mirrors"
        case .kepler: return "Walls"
        case .maxwell: return "Fixed optics"
        case .pascal: return "Beam splitters"
        case .volta: return "Multiple sources"
        case .turing: return "Colour filters"
        case .ampere: return "Additive mixing"
        case .hopper: return "Split spectra"
        case .blackwell: return "Everything at scale"
        case .rubin: return "Interference"
        case .daily: return "Seeded, one per day"
        }
    }
}

public struct Level: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let chapter: Chapter
    /// 1-based position within the chapter (or the day number for dailies).
    public let index: Int
    public let width: Int
    public let height: Int
    /// Immutable pieces: walls, emitters, targets and any pre-placed optics.
    public let fixed: [GridPoint: Piece]
    /// Pieces the player may place, in the order shown in the tray.
    public let inventory: [PieceKind]
    /// A known-good placement; used by tests, the hint button and the generator.
    public let solution: [GridPoint: Piece]
    public let hint: String?

    public init(id: String, title: String, chapter: Chapter, index: Int, width: Int, height: Int,
                fixed: [GridPoint: Piece], inventory: [PieceKind], solution: [GridPoint: Piece], hint: String? = nil) {
        self.id = id
        self.title = title
        self.chapter = chapter
        self.index = index
        self.width = width
        self.height = height
        self.fixed = fixed
        self.inventory = inventory
        self.solution = solution
        self.hint = hint
    }

    /// Number of pieces the reference solution uses.
    public var par: Int { solution.count }

    public var targets: [GridPoint: BeamColor] {
        var result: [GridPoint: BeamColor] = [:]
        for (p, piece) in fixed {
            if case .target(let c) = piece { result[p] = c }
        }
        return result
    }

    public var emitters: [(position: GridPoint, direction: Direction, color: BeamColor)] {
        fixed.compactMap { p, piece in
            if case .emitter(let d, let c) = piece { return (p, d, c) }
            return nil
        }.sorted { ($0.position.y, $0.position.x) < ($1.position.y, $1.position.x) }
    }

    public func contains(_ p: GridPoint) -> Bool {
        p.x >= 0 && p.y >= 0 && p.x < width && p.y < height
    }

    public func isFree(_ p: GridPoint) -> Bool {
        contains(p) && fixed[p] == nil
    }

    public var displayName: String {
        chapter == .daily ? "Daily #\(index)" : "\(chapter.name) \(index)"
    }
}

public enum LevelSpecError: Error, Equatable, CustomStringConvertible {
    case ragged(String)
    case unknownGlyph(Character, GridPoint)
    case solutionSizeMismatch(String)
    case solutionOverlapsFixed(GridPoint)

    public var description: String {
        switch self {
        case .ragged(let id): return "\(id): rows have different widths"
        case .unknownGlyph(let c, let p): return "unknown glyph '\(c)' at \(p)"
        case .solutionSizeMismatch(let id): return "\(id): solution grid size differs from board"
        case .solutionOverlapsFixed(let p): return "solution places a piece on a fixed cell \(p)"
        }
    }
}

/// ASCII level authoring format.
///
/// Board glyphs: `.` empty, `#` wall, `> < ^ v` emitter (green unless overridden),
/// `O` green target, `R G B Y M C W` coloured target, `/` `\` fixed mirror,
/// `S` fixed splitter (`/` orientation), `Z` fixed splitter (`\` orientation),
/// `F` fixed filter (green unless overridden).
///
/// Solution glyphs (same size, only the player's pieces): `/` `\` mirror, `S` `Z`
/// splitter, `F` filter. `colors` overrides the colour of emitters and filters
/// (board or solution) at the given cells.
public enum LevelSpec {
    public static func parse(id: String, title: String, chapter: Chapter, index: Int,
                             board: String, solution: String, colors: [GridPoint: BeamColor] = [:],
                             hint: String? = nil) throws -> Level {
        let boardRows = rows(board)
        let width = boardRows.first?.count ?? 0
        let height = boardRows.count
        guard boardRows.allSatisfy({ $0.count == width }) else { throw LevelSpecError.ragged(id) }

        var fixed: [GridPoint: Piece] = [:]
        for (y, row) in boardRows.enumerated() {
            for (x, glyph) in row.enumerated() {
                let p = GridPoint(x, y)
                if let piece = try piece(for: glyph, at: p, colors: colors) {
                    fixed[p] = piece
                }
            }
        }

        let solutionRows = rows(solution)
        guard solutionRows.count == height, solutionRows.allSatisfy({ $0.count == width }) else {
            throw LevelSpecError.solutionSizeMismatch(id)
        }
        var placed: [GridPoint: Piece] = [:]
        for (y, row) in solutionRows.enumerated() {
            for (x, glyph) in row.enumerated() {
                let p = GridPoint(x, y)
                guard let piece = try piece(for: glyph, at: p, colors: colors) else { continue }
                guard fixed[p] == nil else { throw LevelSpecError.solutionOverlapsFixed(p) }
                placed[p] = piece
            }
        }

        let inventory = placed
            .sorted { ($0.key.y, $0.key.x) < ($1.key.y, $1.key.x) }
            .compactMap { $0.value.kind }
            .sorted(by: trayOrder)

        return Level(id: id, title: title, chapter: chapter, index: index, width: width, height: height,
                     fixed: fixed, inventory: inventory, solution: placed, hint: hint)
    }

    /// Mirrors first, then splitters, then filters in spectrum order.
    static func trayOrder(_ a: PieceKind, _ b: PieceKind) -> Bool {
        func rank(_ k: PieceKind) -> Int {
            switch k {
            case .mirror: return 0
            case .splitter: return 1
            case .filter(let c): return 10 + Int(c.rawValue)
            }
        }
        return rank(a) < rank(b)
    }

    static func rows(_ text: String) -> [[Character]] {
        text.split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map(Array.init)
    }

    static func piece(for glyph: Character, at p: GridPoint, colors: [GridPoint: BeamColor]) throws -> Piece? {
        let tint = colors[p] ?? .green
        switch glyph {
        case ".": return nil
        case "#": return .wall
        case ">": return .emitter(.right, tint)
        case "<": return .emitter(.left, tint)
        case "^": return .emitter(.up, tint)
        case "v": return .emitter(.down, tint)
        case "O": return .target(.green)
        case "/": return .mirror(.slash)
        case "\\": return .mirror(.backslash)
        case "S": return .splitter(.slash)
        case "Z": return .splitter(.backslash)
        case "F": return .filter(tint)
        default:
            if let c = BeamColor(code: glyph) { return .target(c) }
            throw LevelSpecError.unknownGlyph(glyph, p)
        }
    }
}
