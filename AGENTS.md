# AGENTS.md — RTX ON (SwiftUI, iOS)

Guidance for AI software engineering agents working in this repository.

## What this is

A native SwiftUI ray-tracing puzzle game for **iOS 17+ (iPhone and iPad)**, built with Xcode on macOS, plus a WidgetKit extension (`rtx-smi`) that renders the device like `nvidia-smi`. It is a demo artifact meant to be handed to engineers to play. There is no backend, no accounts, no analytics, no network access. Not affiliated with NVIDIA; the palette (black, `#76B900`) and architecture names are used in tribute.

## Layout

See README.md. The short version: `Core/` is the Swift package `RTXOnCore` (tracer, levels, daily generator, progress, share card, SMI table), `App/` is the XcodeGen-generated Xcode project with the app, widget extension, and simulator tests.

## Rules

1. **Keep `Core/` Foundation-only.** No SwiftUI, UIKit, WidgetKit, Metal or Combine in `Core/`; `swift test` must keep running on Linux CI. UI, persistence (`UserDefaults`), and device capture (`ProcessInfo`, Mach) live in `App/`.
2. **Levels must prove themselves.** Every campaign level carries a reference solution. `LevelTests` asserts the solution solves it, the empty board does not, and the inventory matches the solution. Do not weaken these tests to land a level; fix the level. The daily generator is covered by a three-year no-fallback test — keep it green when changing `Daily.swift`.
3. **Never `!`-unwrap a lookup.** `LevelPack.level(id:)`, `Progress.result(for:)`, dictionary reads on the board — all optional, all handled.
4. **Share cards stay spoiler-free.** `ShareCard.text` may show which cells were lit and the piece count; it must never encode where mirrors/splitters/filters were placed.
5. **The RTX toggle changes rendering only.** Never let `rtxEnabled` influence `Tracer` results or scoring.
6. **No framework-breaking changes.** Do not raise the deployment target, change the Swift language mode, or add third-party dependencies.
7. **Always run** `cd Core && swift test` (Linux or macOS) and `scripts/verify-ios.sh` (macOS) before opening a PR. Both must pass. Report the commit SHA, Xcode version and simulator that were verified.
8. **Simulator verification before merge.** UI changes are verified by a macOS session that runs `RECORD=1 scripts/verify-ios.sh`, plays at least one level to the solved sheet, toggles RTX, opens `rtx-smi`, and attaches the recording to the PR. Use `RESET=1` to start from zero progress.
9. **Metal shaders** live in `App/RTXOn/Features/Play/RTXShaders.metal` and are used via `ShaderLibrary`/`layerEffect`. Only `[[stitchable]]` functions; keep them cheap — they run per frame on the beam layer.
10. Never reference or link public GitHub issues in commits, PRs, or comments.
11. Synthetic data only; do not add real accounts or NVIDIA-internal identifiers.

## Commands

```
cd Core && swift test                          # Linux or macOS
scripts/bootstrap-macos.sh                     # macOS: brew install xcodegen, generate App/RTXOn.xcodeproj
scripts/verify-ios.sh                          # macOS: build + unit tests + install + launch on an iPhone simulator
RECORD=1 RESET=1 scripts/verify-ios.sh         # same, fresh progress, recording to artifacts/ios-run.mp4
SIMULATOR="iPhone 16 Pro" scripts/verify-ios.sh
open App/RTXOn.xcodeproj                       # work in Xcode
```
