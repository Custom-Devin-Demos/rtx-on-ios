# RTX ON — a ray-tracing puzzle for iOS

Route light through mirrors, splitters and colour filters until every target is lit. Ten chapters named for GPU architectures (Fermi → Rubin), a daily board that is the same for everyone, spoiler-free share cards, and an `rtx-smi` widget that renders your phone the way `nvidia-smi` renders a GPU.

Native SwiftUI, iOS 17+, iPhone and iPad. No accounts, no network, no analytics. Not affiliated with or endorsed by NVIDIA.

## Play

- **Campaign** — 30 hand-built levels, 3 per architecture. Each chapter introduces one idea: reflection, splitting, colour filtering, additive mixing, then combinations. Chapters unlock as you clear the previous one.
- **Daily** — generated from the day number with a seeded PRNG, so the whole channel gets the same puzzle. Ramps in difficulty through the week. Streaks are tracked.
- **RTX ON / OFF** — the switch in the top right changes the renderer only. OFF is flat rasterised lines. ON adds a soft beam core, a pulse, and a Metal bloom (`layerEffect`) so light bleeds into the board.
- **Share** — a text card with piece count vs par, bounces, and an emoji map of which cells were lit. It never shows where your mirrors went.
- **rtx-smi** — real thermal state, memory, cores, uptime and Low Power Mode in a fixed-width table; your progress is the process list. Also a Home Screen (medium, large) and Lock Screen (rectangular) widget.

## Layout

```
Core/                             Swift package `RTXOnCore` — Foundation only; `swift test` runs on Linux and macOS
  Sources/RTXOnCore/
    Geometry.swift                GridPoint, Direction, mirror reflection
    Pieces.swift                  BeamColor (RGB OptionSet), Piece, PieceKind
    Level.swift                   Level, Chapter, ASCII LevelSpec parser
    Tracer.swift                  the ray tracer: Tracer.trace(level:placements:) -> TraceResult
    LevelPack.swift               the 30 campaign levels (ASCII art + reference solutions)
    Daily.swift                   SeededGenerator + Daily.level(day:) with validity checks
    Progress.swift                Codable progress, unlocks, streaks
    ShareCard.swift               spoiler-free share text
    SMIReport.swift               nvidia-smi-style table renderer
  Tests/RTXOnCoreTests/           XCTest — tracer, every campaign level solves, daily never falls back for 3 years
App/
  project.yml                     XcodeGen spec -> App/RTXOn.xcodeproj (generated, git-ignored)
  RTXOn/                          the app: RTXOnApp (routes), Core/{Theme,AppState}, Features/{Home,Play,SMI,About}
  RTXOn/Features/Play/            BoardView (Canvas), RTXShaders.metal (bloom), PuzzleViewModel, SolvedSheet
  RTXOnWidget/                    WidgetKit extension (rtx-smi)
  Shared/                         SharedStore (App Group defaults), DeviceReport (live device capture)
  RTXOnTests/                     XCTest for PuzzleViewModel / AppState (iOS simulator)
scripts/bootstrap-macos.sh        install xcodegen + generate the project
scripts/verify-ios.sh             build, test, install, launch (RECORD=1 records the simulator)
```

## Build

```sh
cd Core && swift test                 # Linux or macOS
scripts/bootstrap-macos.sh            # macOS: generate App/RTXOn.xcodeproj
scripts/verify-ios.sh                 # macOS: build + unit tests + install + launch on an iPhone simulator
RECORD=1 scripts/verify-ios.sh        # same, recording to artifacts/ios-run.mp4
open App/RTXOn.xcodeproj              # work in Xcode
```

## How the tracer works

Every emitter starts a ray with a direction and a colour. Rays walk cell by cell. Empty cells pass; walls, emitters and the board edge stop the ray; targets absorb it and accumulate colour additively (`red + green` lights a `yellow` target). `/` and `\` mirrors reflect; splitters reflect *and* pass; filters intersect the beam colour with their own and drop the ray if nothing survives. Rays are keyed on `(cell, direction, colour)`, so splitter loops terminate, and there is a hard segment cap as a backstop. A level is solved when every target holds exactly its required colour and no target is lit with the wrong one.

## Adding a level

Levels are ASCII in `LevelPack.swift`:

```
. empty   # wall   > < ^ v emitter (direction)   O green target   R G B Y M C W coloured target
/ \ mirror   S Z splitter (/ \)   F filter
```

Emitters and filters default to green; pass `colors: [GridPoint: BeamColor]` to override them per cell. Give the level an inventory, a reference solution, and a hint; `LevelTests` will fail if the reference solution doesn't solve it or if the empty board already does.
