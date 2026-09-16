import RTXOnCore
import SwiftUI

struct PuzzleView: View {
    @Environment(AppState.self) private var appState
    @State private var model: PuzzleViewModel
    @State private var showSolved = false
    @State private var confirmSolution = false

    init(level: Level) {
        _model = State(initialValue: PuzzleViewModel(level: level))
    }

    var level: Level { model.level }

    var body: some View {
        VStack(spacing: 12) {
            header
            BoardView(level: level, placements: model.placements, trace: model.trace,
                      rtxEnabled: appState.rtxEnabled, onTap: { model.tap($0) })
                .padding(.horizontal, 12)
                .sensoryFeedback(.impact(weight: .light), trigger: model.piecesUsed)
                .sensoryFeedback(.success, trigger: model.isSolved) { _, solved in solved }
            status
            TrayView(model: model)
            controls
        }
        .padding(.bottom, 8)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(level.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                RTXToggle()
            }
        }
        .onChange(of: model.isSolved) { _, solved in
            guard solved else { return }
            appState.recordSolve(level: level, pieces: model.piecesUsed, bounces: model.trace.bounces)
            Task {
                try? await Task.sleep(for: .milliseconds(650))
                showSolved = true
            }
        }
        .sheet(isPresented: $showSolved) {
            SolvedSheet(level: level, placements: model.placements, trace: model.trace) {
                showSolved = false
                appState.advance(from: level)
            }
            .presentationDetents([.medium, .large])
            .presentationBackground(Theme.surface)
        }
        .confirmationDialog("Show the solution?", isPresented: $confirmSolution, titleVisibility: .visible) {
            Button("Place the reference solution", role: .destructive) { model.revealSolution() }
        } message: {
            Text("It still counts, but you'll know.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Eyebrow(text: level.chapter == .daily ? "Daily puzzle" : "\(level.chapter.name) · \(level.chapter.mechanic)")
                Spacer()
                Text("Par \(level.par)")
                    .font(Theme.mono(12, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
            }
            Text(level.chapter == .daily ? "Day \(level.index)" : level.title)
                .font(Theme.display(26))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    private var status: some View {
        HStack(spacing: 14) {
            let lit = model.trace.litTargets.count
            let total = level.targets.count
            Label("\(lit)/\(total) targets", systemImage: lit == total ? "checkmark.circle.fill" : "scope")
                .foregroundStyle(lit == total ? Theme.green : Theme.textSecondary)
            Label("\(model.trace.bounces) bounces", systemImage: "arrow.triangle.turn.up.right.diamond")
                .foregroundStyle(Theme.textSecondary)
            if !model.trace.mislitTargets.isEmpty {
                Label("wrong colour", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(Theme.danger)
            }
            Spacer()
        }
        .font(Theme.mono(12, weight: .medium))
        .padding(.horizontal, 20)
        .animation(.easeOut(duration: 0.2), value: model.trace.litTargets.count)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            if model.hintShown, let hint = level.hint {
                Text(hint)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .transition(.opacity)
            }
            HStack(spacing: 10) {
                ControlButton(title: "Undo", icon: "arrow.uturn.backward", enabled: model.canUndo) { model.undo() }
                ControlButton(title: "Clear", icon: "xmark", enabled: model.piecesUsed > 0) { model.reset() }
                if level.hint != nil {
                    ControlButton(title: "Hint", icon: "lightbulb", enabled: !model.hintShown) { model.showHint() }
                }
                ControlButton(title: "Solve", icon: "wand.and.stars", enabled: !model.isSolved) { confirmSolution = true }
            }
            .padding(.horizontal, 20)
        }
        .animation(.easeOut(duration: 0.2), value: model.hintShown)
    }
}

struct ControlButton: View {
    let title: String
    let icon: String
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 15, weight: .semibold))
                Text(title).font(.system(size: 11, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundStyle(enabled ? Theme.textPrimary : Theme.textTertiary)
            .card(raised: true)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

/// The RTX ON / OFF switch, styled like the badge.
struct RTXToggle: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) { appState.rtxEnabled.toggle() }
        } label: {
            HStack(spacing: 6) {
                Text("RTX")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(appState.rtxEnabled ? Color.black : Theme.textSecondary)
                Text(appState.rtxEnabled ? "ON" : "OFF")
                    .font(Theme.mono(12, weight: .bold))
                    .foregroundStyle(appState.rtxEnabled ? Color.black : Theme.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(appState.rtxEnabled ? Theme.green : Theme.surfaceRaised, in: Capsule())
            .overlay(Capsule().strokeBorder(appState.rtxEnabled ? Theme.green : Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("RTX \(appState.rtxEnabled ? "on" : "off")")
        .accessibilityHint("Toggles ray-traced lighting")
    }
}

/// The inventory of pieces the player can place.
struct TrayView: View {
    @Bindable var model: PuzzleViewModel

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(model.tray.enumerated()), id: \.offset) { _, item in
                let selected = model.selectedTool == item.kind
                Button {
                    model.selectedTool = item.kind
                } label: {
                    HStack(spacing: 10) {
                        PieceGlyph(kind: item.kind)
                            .frame(width: 30, height: 30)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.kind.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text("\(item.remaining) left")
                                .font(Theme.mono(11))
                                .foregroundStyle(item.remaining == 0 ? Theme.textTertiary : Theme.textSecondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selected ? Theme.surfaceRaised : Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(selected ? Theme.green : Theme.stroke, lineWidth: selected ? 1.5 : 1))
                    .opacity(item.remaining == 0 ? 0.55 : 1)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(item.kind.name), \(item.remaining) of \(item.total) left")
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .frame(minHeight: 50)
    }
}

/// Small vector glyph for a piece kind, used in the tray and level lists.
struct PieceGlyph: View {
    let kind: PieceKind

    var body: some View {
        Canvas { ctx, size in
            let r = CGRect(origin: .zero, size: size).insetBy(dx: 4, dy: 4)
            switch kind {
            case .mirror:
                var p = Path()
                p.move(to: CGPoint(x: r.minX, y: r.maxY))
                p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
                ctx.stroke(p, with: .color(.white), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            case .splitter:
                var p = Path()
                p.move(to: CGPoint(x: r.minX, y: r.maxY))
                p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
                ctx.stroke(p, with: .color(.white), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [4, 3]))
            case .filter(let c):
                let inner = r.insetBy(dx: 2, dy: 2)
                ctx.fill(Path(roundedRect: inner, cornerRadius: 4), with: .color(Theme.color(for: c).opacity(0.4)))
                ctx.stroke(Path(roundedRect: inner, cornerRadius: 4), with: .color(Theme.color(for: c)), lineWidth: 1.5)
            }
        }
    }
}
