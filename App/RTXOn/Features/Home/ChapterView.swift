import RTXOnCore
import SwiftUI

struct ChapterView: View {
    @Environment(AppState.self) private var appState
    let chapter: Chapter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(text: "Chapter \(String(format: "%02d", chapter.rawValue)) · \(chapter.year.map(String.init) ?? "")")
                    Text(chapter.name)
                        .font(Theme.display(40, weight: .black))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Named for \(chapter.namesake). Introduces: \(chapter.mechanic.lowercased()).")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textSecondary)
                }
                VStack(spacing: 8) {
                    ForEach(LevelPack.levels(in: chapter)) { level in
                        LevelRow(level: level, result: appState.progress.result(for: level))
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(chapter.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { RTXToggle() } }
    }
}

struct LevelRow: View {
    let level: Level
    let result: RTXOnCore.Progress.Result?

    var body: some View {
        NavigationLink(value: Route.level(level.id)) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(result == nil ? Theme.surfaceRaised : Theme.green)
                    if result != nil {
                        Image(systemName: "checkmark").font(.system(size: 14, weight: .bold)).foregroundStyle(.black)
                    } else {
                        Text("\(level.index)").font(Theme.mono(14, weight: .bold)).foregroundStyle(Theme.textPrimary)
                    }
                }
                .frame(width: 34, height: 34)
                VStack(alignment: .leading, spacing: 3) {
                    Text(level.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    HStack(spacing: 6) {
                        ForEach(Array(level.inventory.enumerated()), id: \.offset) { _, kind in
                            PieceGlyph(kind: kind).frame(width: 16, height: 16)
                        }
                        Text("\(level.width)×\(level.height) · \(level.targets.count) target\(level.targets.count == 1 ? "" : "s")")
                            .font(Theme.mono(11))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                Spacer()
                if let result {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(result.pieces) pc")
                            .font(Theme.mono(12, weight: .bold))
                            .foregroundStyle(result.pieces <= level.par ? Theme.green : Theme.textSecondary)
                        Text("par \(level.par)")
                            .font(Theme.mono(10))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .card()
        }
        .buttonStyle(.plain)
    }
}
