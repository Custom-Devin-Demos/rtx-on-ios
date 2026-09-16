import Foundation

/// Deterministic SplitMix64 so every device gets the same daily puzzle.
public struct SeededGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

public enum Daily {
    /// Day 1 is the launch day; the number shown on the share card.
    public static let epoch: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 1; c.day = 1
        return Calendar(identifier: .gregorian).date(from: c)!
    }()

    public static func dayNumber(for date: Date = Date(), calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: epoch)
        let today = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return max(1, days + 1)
    }

    public static func level(for date: Date = Date(), calendar: Calendar = .current) -> Level {
        level(day: dayNumber(for: date, calendar: calendar))
    }

    public static func level(day: Int) -> Level {
        var rng = SeededGenerator(seed: UInt64(day) &* 0x5DEE_CE66D &+ 0xB)
        // Difficulty ramps through the week and resets, so Mondays are gentle.
        let turns = 2 + (day % 7) / 2
        for _ in 0..<512 {
            if let level = generate(day: day, turns: turns, rng: &rng) {
                return level
            }
        }
        return fallbackLevel(day: day)
    }

    /// An always-valid puzzle for the (never observed) case where generation fails.
    static func fallbackLevel(day: Int) -> Level {
        let board = """
        >......
        .......
        .......
        .......
        .......
        .......
        .......
        .......
        ...O...
        """
        let solution = """
        ...\\...
        .......
        .......
        .......
        .......
        .......
        .......
        .......
        .......
        """
        // Static, well-formed input; parse cannot fail.
        return try! LevelSpec.parse(id: "daily-\(day)", title: "Daily #\(day)", chapter: .daily, index: day,
                                    board: board, solution: solution)
    }

    static let width = 7
    static let height = 9

    private static func generate(day: Int, turns: Int, rng: inout SeededGenerator) -> Level? {
        var fixed: [GridPoint: Piece] = [:]
        var solution: [GridPoint: Piece] = [:]
        var used = Set<GridPoint>()

        // Start on the left edge, heading right.
        var position = GridPoint(0, Int.random(in: 1..<(height - 1), using: &rng))
        var direction = Direction.right
        fixed[position] = .emitter(direction, .green)
        used.insert(position)

        for _ in 0..<turns {
            let run = Int.random(in: 1...4, using: &rng)
            var cell = position
            var path: [GridPoint] = []
            for _ in 0..<run {
                cell = cell.moved(direction)
                guard cell.x >= 0, cell.y >= 0, cell.x < width, cell.y < height, !used.contains(cell) else { return nil }
                path.append(cell)
            }
            used.formUnion(path)
            position = cell
            // Choose a turn that keeps us inside the board.
            let candidates = MirrorOrientation.allCases.filter { o in
                let d = direction.reflected(by: o)
                let n = position.moved(d)
                return n.x >= 0 && n.y >= 0 && n.x < width && n.y < height && !used.contains(n)
            }
            guard let orientation = candidates.randomElement(using: &rng) else { return nil }
            solution[position] = .mirror(orientation)
            direction = direction.reflected(by: orientation)
        }

        // Final run to the target.
        let run = Int.random(in: 1...4, using: &rng)
        var cell = position
        for _ in 0..<run {
            cell = cell.moved(direction)
            guard cell.x >= 0, cell.y >= 0, cell.x < width, cell.y < height, !used.contains(cell) else { return nil }
            used.insert(cell)
        }
        fixed[cell] = .target(.green)

        // Sprinkle walls off the path so the obvious straight shots fail.
        let wallCount = 3 + turns
        var placed = 0
        var tries = 0
        while placed < wallCount, tries < 100 {
            tries += 1
            let p = GridPoint(Int.random(in: 0..<width, using: &rng), Int.random(in: 0..<height, using: &rng))
            guard !used.contains(p), fixed[p] == nil else { continue }
            fixed[p] = .wall
            used.insert(p)
            placed += 1
        }

        let inventory = solution.values.compactMap(\.kind).sorted(by: LevelSpec.trayOrder)
        let level = Level(id: "daily-\(day)", title: "Daily #\(day)", chapter: .daily, index: day,
                          width: width, height: height, fixed: fixed, inventory: inventory,
                          solution: solution, hint: nil)
        guard Tracer.trace(level: level, placements: solution).solved,
              !Tracer.trace(level: level, placements: [:]).solved else { return nil }
        return level
    }
}
