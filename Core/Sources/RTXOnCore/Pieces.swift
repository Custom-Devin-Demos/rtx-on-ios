import Foundation

/// Additive RGB light. Beams carry a colour; targets require an exact colour.
public struct BeamColor: OptionSet, Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: UInt8

    public init(rawValue: UInt8) { self.rawValue = rawValue & 0b111 }

    public static let red = BeamColor(rawValue: 0b001)
    public static let green = BeamColor(rawValue: 0b010)
    public static let blue = BeamColor(rawValue: 0b100)
    public static let yellow: BeamColor = [.red, .green]
    public static let magenta: BeamColor = [.red, .blue]
    public static let cyan: BeamColor = [.green, .blue]
    public static let white: BeamColor = [.red, .green, .blue]

    public static let all: [BeamColor] = [.red, .green, .blue, .yellow, .magenta, .cyan, .white]

    public var name: String {
        switch self {
        case .red: return "Red"
        case .green: return "Green"
        case .blue: return "Blue"
        case .yellow: return "Yellow"
        case .magenta: return "Magenta"
        case .cyan: return "Cyan"
        case .white: return "White"
        default: return "Dark"
        }
    }

    /// Single-letter code used by level specs and share cards.
    public var code: Character {
        switch self {
        case .red: return "R"
        case .green: return "G"
        case .blue: return "B"
        case .yellow: return "Y"
        case .magenta: return "M"
        case .cyan: return "C"
        case .white: return "W"
        default: return "-"
        }
    }

    public init?(code: Character) {
        guard let match = BeamColor.all.first(where: { $0.code == code }) else { return nil }
        self = match
    }

    /// Linear RGB components in 0...1.
    public var rgb: (r: Double, g: Double, b: Double) {
        (contains(.red) ? 1 : 0, contains(.green) ? 1 : 0, contains(.blue) ? 1 : 0)
    }

    public var description: String { name }
}

public enum MirrorOrientation: String, Codable, Sendable, CaseIterable {
    /// Bottom-left to top-right.
    case slash
    /// Top-left to bottom-right.
    case backslash

    public var toggled: MirrorOrientation { self == .slash ? .backslash : .slash }
    public var glyph: Character { self == .slash ? "/" : "\\" }
}

/// Everything that can occupy a cell.
public enum Piece: Hashable, Codable, Sendable {
    case wall
    case emitter(Direction, BeamColor)
    case target(BeamColor)
    case mirror(MirrorOrientation)
    /// Half-silvered mirror: the beam passes straight through *and* reflects.
    case splitter(MirrorOrientation)
    /// Passes only the colour components it shares with the beam.
    case filter(BeamColor)

    public var kind: PieceKind? {
        switch self {
        case .mirror: return .mirror
        case .splitter: return .splitter
        case .filter(let c): return .filter(c)
        case .wall, .emitter, .target: return nil
        }
    }

    public var isTarget: Bool {
        if case .target = self { return true }
        return false
    }

    public var isEmitter: Bool {
        if case .emitter = self { return true }
        return false
    }

    /// Piece with its orientation flipped; non-orientable pieces are unchanged.
    public var rotated: Piece {
        switch self {
        case .mirror(let o): return .mirror(o.toggled)
        case .splitter(let o): return .splitter(o.toggled)
        default: return self
        }
    }
}

/// A piece the player can take from the inventory and drop on the board.
public enum PieceKind: Hashable, Codable, Sendable, CustomStringConvertible {
    case mirror
    case splitter
    case filter(BeamColor)

    /// The piece created when this kind is first placed.
    public var initialPiece: Piece {
        switch self {
        case .mirror: return .mirror(.slash)
        case .splitter: return .splitter(.slash)
        case .filter(let c): return .filter(c)
        }
    }

    public var name: String {
        switch self {
        case .mirror: return "Mirror"
        case .splitter: return "Splitter"
        case .filter(let c): return "\(c.name) filter"
        }
    }

    public var description: String { name }
}
