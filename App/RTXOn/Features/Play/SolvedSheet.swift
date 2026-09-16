import RTXOnCore
import SwiftUI

struct SolvedSheet: View {
    @Environment(AppState.self) private var appState
    let level: Level
    let placements: [GridPoint: Piece]
    let trace: TraceResult
    let onContinue: () -> Void

    private var card: String { ShareCard.text(level: level, placements: placements, trace: trace) }
    private var underPar: Bool { placements.count < level.par }
    private var nextLevel: Level? { level.chapter == .daily ? nil : LevelPack.next(after: level) }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: underPar ? "Under par" : "Solved")
                    Text(level.displayName)
                        .font(Theme.display(28))
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Theme.green)
            }

            HStack(spacing: 12) {
                Stat(value: "\(placements.count)", label: "pieces", detail: "par \(level.par)")
                Stat(value: "\(trace.bounces)", label: "bounces", detail: "\(trace.segments.count) rays")
                if level.chapter == .daily {
                    Stat(value: "\(appState.streak)", label: "streak", detail: appState.streak == 1 ? "day" : "days")
                } else {
                    Stat(value: "\(appState.progress.campaignCompleted)", label: "solved", detail: "of \(LevelPack.levels.count)")
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                Text(card)
                    .font(Theme.mono(13))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(14)
            }
            .background(Theme.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.stroke, lineWidth: 1))

            HStack(spacing: 10) {
                ShareLink(item: card) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .foregroundStyle(Theme.textPrimary)
                        .card(raised: true)
                }
                Button(action: onContinue) {
                    Text(nextLevel.map { "Next: \($0.displayName)" } ?? (level.chapter == .daily ? "Done" : "Back to chapters"))
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .foregroundStyle(.black)
                        .background(Theme.green, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct Stat: View {
    let value: String
    let label: String
    var detail: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(Theme.mono(24, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Theme.green)
            if let detail {
                Text(detail)
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .card()
    }
}
