import Foundation

/// Integer cell coordinate. `x` grows to the right, `y` grows downward.
public struct GridPoint: Hashable, Codable, Sendable, CustomStringConvertible {
    public var x: Int
    public var y: Int

    public init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }

    public func moved(_ direction: Direction) -> GridPoint {
        GridPoint(x + direction.dx, y + direction.dy)
    }

    public var description: String { "(\(x),\(y))" }
}

/// Continuous coordinate in cell units; (0.5, 0.5) is the centre of cell (0,0).
public struct Vec2: Hashable, Sendable {
    public var x: Double
    public var y: Double

    public init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }

    public static func center(of p: GridPoint) -> Vec2 {
        Vec2(Double(p.x) + 0.5, Double(p.y) + 0.5)
    }

    /// Point on the edge of cell `p` facing `direction`.
    public static func edge(of p: GridPoint, facing direction: Direction) -> Vec2 {
        let c = center(of: p)
        return Vec2(c.x + Double(direction.dx) * 0.5, c.y + Double(direction.dy) * 0.5)
    }
}

public enum Direction: String, CaseIterable, Codable, Sendable {
    case up, down, left, right

    public var dx: Int {
        switch self {
        case .left: return -1
        case .right: return 1
        case .up, .down: return 0
        }
    }

    public var dy: Int {
        switch self {
        case .up: return -1
        case .down: return 1
        case .left, .right: return 0
        }
    }

    public var opposite: Direction {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }

    public var isHorizontal: Bool { self == .left || self == .right }

    /// Direction after bouncing off a mirror of the given orientation.
    ///
    /// `/` runs bottom-left to top-right: right→up, up→right, left→down, down→left.
    /// `\` runs top-left to bottom-right: right→down, down→right, left→up, up→left.
    public func reflected(by orientation: MirrorOrientation) -> Direction {
        switch (orientation, self) {
        case (.slash, .right): return .up
        case (.slash, .up): return .right
        case (.slash, .left): return .down
        case (.slash, .down): return .left
        case (.backslash, .right): return .down
        case (.backslash, .down): return .right
        case (.backslash, .left): return .up
        case (.backslash, .up): return .left
        }
    }

    /// Rotation in degrees for drawing a glyph that points right by default.
    public var rotationDegrees: Double {
        switch self {
        case .right: return 0
        case .down: return 90
        case .left: return 180
        case .up: return 270
        }
    }
}
