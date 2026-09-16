import RTXOnCore
import SwiftUI

/// The playfield: grid, fixed pieces, player's pieces and the traced beams.
struct BoardView: View {
    let level: Level
    let placements: [GridPoint: Piece]
    let trace: TraceResult
    let rtxEnabled: Bool
    let onTap: (GridPoint) -> Void

    var body: some View {
        GeometryReader { geo in
            let cell = floor(min(geo.size.width / CGFloat(level.width), geo.size.height / CGFloat(level.height)))
            let boardSize = CGSize(width: cell * CGFloat(level.width), height: cell * CGFloat(level.height))
            let origin = CGPoint(x: (geo.size.width - boardSize.width) / 2, y: (geo.size.height - boardSize.height) / 2)

            ZStack {
                Canvas { ctx, _ in
                    drawGrid(ctx, cell: cell)
                    drawPieces(ctx, cell: cell)
                }
                if rtxEnabled {
                    TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                        let t = timeline.date.timeIntervalSinceReferenceDate
                        BeamLayer(level: level, trace: trace, cell: cell, rtx: true, time: t)
                    }
                } else {
                    BeamLayer(level: level, trace: trace, cell: cell, rtx: false, time: 0)
                }
                Canvas { ctx, _ in
                    drawTargets(ctx, cell: cell)
                }
            }
            .frame(width: boardSize.width, height: boardSize.height)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.stroke, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .local) { location in
                let p = GridPoint(Int(location.x / cell), Int(location.y / cell))
                if level.contains(p) { onTap(p) }
            }
            .offset(x: origin.x, y: origin.y)
            .accessibilityLabel("Puzzle board, \(level.width) by \(level.height)")
        }
    }

    // MARK: Drawing

    private func rect(_ p: GridPoint, cell: CGFloat, inset: CGFloat = 0) -> CGRect {
        CGRect(x: CGFloat(p.x) * cell, y: CGFloat(p.y) * cell, width: cell, height: cell).insetBy(dx: inset, dy: inset)
    }

    private func drawGrid(_ ctx: GraphicsContext, cell: CGFloat) {
        for y in 0..<level.height {
            for x in 0..<level.width {
                let p = GridPoint(x, y)
                let r = rect(p, cell: cell, inset: 1.5)
                let path = Path(roundedRect: r, cornerRadius: 4)
                ctx.fill(path, with: .color(Color(white: 0.095)))
                if level.isFree(p), placements[p] == nil {
                    ctx.fill(Path(ellipseIn: CGRect(x: r.midX - 1, y: r.midY - 1, width: 2, height: 2)),
                             with: .color(Color(white: 0.2)))
                }
            }
        }
    }

    private func drawPieces(_ ctx: GraphicsContext, cell: CGFloat) {
        for (p, piece) in level.fixed {
            draw(piece, at: p, fixed: true, ctx: ctx, cell: cell)
        }
        for (p, piece) in placements where level.isFree(p) {
            draw(piece, at: p, fixed: false, ctx: ctx, cell: cell)
        }
    }

    private func draw(_ piece: Piece, at p: GridPoint, fixed: Bool, ctx: GraphicsContext, cell: CGFloat) {
        let r = rect(p, cell: cell, inset: 1.5)
        switch piece {
        case .wall:
            ctx.fill(Path(roundedRect: r, cornerRadius: 4), with: .color(Color(white: 0.22)))
            ctx.stroke(Path(roundedRect: r.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 4), with: .color(Color(white: 0.3)), lineWidth: 1)
        case .emitter(let d, let c):
            let inner = r.insetBy(dx: cell * 0.14, dy: cell * 0.14)
            ctx.fill(Path(roundedRect: inner, cornerRadius: 5), with: .color(Color(white: 0.18)))
            ctx.stroke(Path(roundedRect: inner, cornerRadius: 5), with: .color(Theme.color(for: c)), lineWidth: 1.5)
            var tri = Path()
            let s = cell * 0.18
            tri.move(to: CGPoint(x: -s * 0.8, y: -s))
            tri.addLine(to: CGPoint(x: s, y: 0))
            tri.addLine(to: CGPoint(x: -s * 0.8, y: s))
            tri.closeSubpath()
            let transform = CGAffineTransform(translationX: r.midX, y: r.midY).rotated(by: d.rotationDegrees * .pi / 180)
            ctx.fill(tri.applying(transform), with: .color(Theme.color(for: c)))
        case .target:
            break // drawn above the beams in drawTargets
        case .mirror(let o):
            let line = diagonal(o, in: r, inset: cell * 0.18)
            ctx.stroke(line, with: .color(fixed ? Color(white: 0.5) : Color(white: 0.95)), style: StrokeStyle(lineWidth: max(3, cell * 0.11), lineCap: .round))
            ctx.stroke(line, with: .color(fixed ? Color(white: 0.3) : Theme.green.opacity(0.7)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
        case .splitter(let o):
            let line = diagonal(o, in: r, inset: cell * 0.18)
            ctx.stroke(line, with: .color(fixed ? Color(white: 0.45) : Color(white: 0.9)), style: StrokeStyle(lineWidth: max(3, cell * 0.11), lineCap: .round, dash: [cell * 0.14, cell * 0.1]))
        case .filter(let c):
            let inner = r.insetBy(dx: cell * 0.2, dy: cell * 0.2)
            ctx.fill(Path(roundedRect: inner, cornerRadius: 4), with: .color(Theme.color(for: c).opacity(fixed ? 0.25 : 0.4)))
            ctx.stroke(Path(roundedRect: inner, cornerRadius: 4), with: .color(Theme.color(for: c, muted: fixed)), lineWidth: 1.5)
        }
    }

    private func drawTargets(_ ctx: GraphicsContext, cell: CGFloat) {
        for (p, want) in level.targets {
            let r = rect(p, cell: cell, inset: 1.5)
            let lit = trace.litTargets.contains(p)
            let mislit = trace.mislitTargets.contains(p)
            let color = Theme.color(for: want)
            let ring = Path(ellipseIn: r.insetBy(dx: cell * 0.22, dy: cell * 0.22))
            if lit {
                ctx.fill(ring, with: .color(color.opacity(0.35)))
                if rtxEnabled {
                    var glow = ctx
                    glow.addFilter(.blur(radius: cell * 0.18))
                    glow.fill(ring, with: .color(color.opacity(0.8)))
                }
            }
            ctx.stroke(ring, with: .color(mislit ? Theme.danger : color), lineWidth: lit ? 3 : 2)
            let dot = Path(ellipseIn: r.insetBy(dx: cell * 0.40, dy: cell * 0.40))
            ctx.fill(dot, with: .color(lit ? .white : (mislit ? Theme.danger : color.opacity(0.7))))
            if mislit, let got = trace.targetColors[p] {
                ctx.fill(Path(ellipseIn: CGRect(x: r.maxX - cell * 0.28, y: r.minY + cell * 0.08, width: cell * 0.2, height: cell * 0.2)),
                         with: .color(Theme.color(for: got)))
            }
        }
    }

    private func diagonal(_ o: MirrorOrientation, in r: CGRect, inset: CGFloat) -> Path {
        var path = Path()
        switch o {
        case .slash:
            path.move(to: CGPoint(x: r.minX + inset, y: r.maxY - inset))
            path.addLine(to: CGPoint(x: r.maxX - inset, y: r.minY + inset))
        case .backslash:
            path.move(to: CGPoint(x: r.minX + inset, y: r.minY + inset))
            path.addLine(to: CGPoint(x: r.maxX - inset, y: r.maxY - inset))
        }
        return path
    }
}

/// Beams only, so the RTX bloom shader samples just the light.
struct BeamLayer: View {
    let level: Level
    let trace: TraceResult
    let cell: CGFloat
    let rtx: Bool
    let time: TimeInterval

    var body: some View {
        let canvas = Canvas(rendersAsynchronously: false) { ctx, _ in
            for seg in trace.segments {
                let a = CGPoint(x: seg.start.x * cell, y: seg.start.y * cell)
                let b = CGPoint(x: seg.end.x * cell, y: seg.end.y * cell)
                var path = Path()
                path.move(to: a)
                path.addLine(to: b)
                let color = Theme.color(for: seg.color)
                if rtx {
                    let pulse = 0.85 + 0.15 * sin(time * 3 + Double(seg.start.x + seg.start.y))
                    ctx.stroke(path, with: .color(color.opacity(0.35 * pulse)), style: StrokeStyle(lineWidth: cell * 0.30, lineCap: .round))
                    ctx.stroke(path, with: .color(color.opacity(0.9)), style: StrokeStyle(lineWidth: cell * 0.10, lineCap: .round))
                    ctx.stroke(path, with: .color(.white.opacity(0.9 * pulse)), style: StrokeStyle(lineWidth: cell * 0.035, lineCap: .round))
                } else {
                    ctx.stroke(path, with: .color(color.opacity(0.85)), style: StrokeStyle(lineWidth: 2, lineCap: .butt))
                }
            }
        }
        if rtx {
            canvas
                .layerEffect(
                    ShaderLibrary.rtxBloom(.float(Float(cell * 0.35)), .float(0.9)),
                    maxSampleOffset: CGSize(width: cell * 0.35, height: cell * 0.35)
                )
                .allowsHitTesting(false)
        } else {
            canvas.allowsHitTesting(false)
        }
    }
}
