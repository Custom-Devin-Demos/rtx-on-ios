import RTXOnCore
import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                hero
                continueCard
                dailyCard
                chapters
                utilities
                footer
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { RTXToggle() }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("RTX")
                    .font(Theme.display(54, weight: .black))
                    .foregroundStyle(Theme.textPrimary)
                Text(" ON")
                    .font(Theme.display(54, weight: .black))
                    .foregroundStyle(Theme.green)
            }
            .tracking(-1.5)
            Text("A ray-tracing puzzle. Bounce light through mirrors, splitters and filters until every target is lit.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    private var continueCard: some View {
        let progress = appState.progress
        let next = progress.nextLevel
        return Button {
            if let next { appState.open(next) }
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: progress.campaignCompleted == 0 ? "Start" : (next == nil ? "Campaign complete" : "Continue"))
                    Text(next?.displayName ?? "All \(LevelPack.levels.count) levels solved")
                        .font(Theme.display(22))
                        .foregroundStyle(Theme.textPrimary)
                    if let next {
                        Text(next.title)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Spacer()
                ProgressRing(fraction: Double(progress.campaignCompleted) / Double(max(1, LevelPack.levels.count)),
                             label: "\(progress.campaignCompleted)/\(LevelPack.levels.count)")
                    .frame(width: 60, height: 60)
            }
            .padding(18)
            .card(raised: true)
        }
        .buttonStyle(.plain)
        .disabled(next == nil)
    }

    private var dailyCard: some View {
        Button {
            appState.open(appState.dailyLevel)
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Daily · #\(appState.today)")
                    Text(appState.dailySolvedToday ? "Solved. Come back tomorrow." : "Today's puzzle")
                        .font(Theme.display(20))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Same board for everyone. \(appState.streak == 0 ? "Start a streak." : "Streak: \(appState.streak) day\(appState.streak == 1 ? "" : "s").")")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: appState.dailySolvedToday ? "checkmark.circle.fill" : "calendar")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(appState.dailySolvedToday ? Theme.green : Theme.textSecondary)
            }
            .padding(18)
            .card()
        }
        .buttonStyle(.plain)
    }

    private var chapters: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Campaign · \(Chapter.campaign.count) architectures")
            VStack(spacing: 8) {
                ForEach(Chapter.campaign, id: \.self) { chapter in
                    ChapterRow(chapter: chapter)
                }
            }
        }
    }

    private var utilities: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Utilities")
            NavigationLink(value: Route.smi) {
                HStack {
                    Image(systemName: "terminal")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.green)
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("rtx-smi")
                            .font(Theme.mono(15, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("This device, in a familiar table. Also a Home Screen widget.")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(Theme.textTertiary)
                }
                .padding(14)
                .card()
            }
            .buttonStyle(.plain)
        }
    }

    private var footer: some View {
        NavigationLink(value: Route.about) {
            Text("About · how the tracer works")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
        }
        .buttonStyle(.plain)
    }
}

struct ChapterRow: View {
    @Environment(AppState.self) private var appState
    let chapter: Chapter

    var body: some View {
        let unlocked = appState.progress.isUnlocked(chapter)
        let done = appState.progress.completed(in: chapter)
        let total = LevelPack.levels(in: chapter).count
        NavigationLink(value: Route.chapter(chapter)) {
            HStack(spacing: 14) {
                Text(String(format: "%02d", chapter.rawValue))
                    .font(Theme.mono(13, weight: .bold))
                    .foregroundStyle(unlocked ? Theme.green : Theme.textTertiary)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(chapter.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(unlocked ? Theme.textPrimary : Theme.textTertiary)
                        if let year = chapter.year {
                            Text(String(year))
                                .font(Theme.mono(11))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    Text(chapter.mechanic)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    ForEach(0..<total, id: \.self) { i in
                        Circle()
                            .fill(i < done ? Theme.green : Theme.stroke)
                            .frame(width: 7, height: 7)
                    }
                }
                Image(systemName: unlocked ? "chevron.right" : "lock.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .card()
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }
}

struct ProgressRing: View {
    let fraction: Double
    let label: String

    var body: some View {
        ZStack {
            Circle().stroke(Theme.stroke, lineWidth: 5)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Theme.green, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(label)
                .font(Theme.mono(11, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
        }
    }
}
