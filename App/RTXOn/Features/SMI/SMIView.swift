import RTXOnCore
import SwiftUI

/// `rtx-smi`: this device rendered like an nvidia-smi dump, refreshed every second.
struct SMIView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(text: "Utility")
                    Text("rtx-smi")
                        .font(Theme.mono(34, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Every value is real: thermal state, memory, cores, uptime, Low Power Mode. The process table is your progress. Add the widget to your Home Screen or Lock Screen.")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                }

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let report = SMIReport.capture(progress: appState.progress, now: context.date)
                    VStack(spacing: 12) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(report.text)
                                .font(Theme.mono(11.5))
                                .foregroundStyle(Theme.green)
                                .padding(14)
                        }
                        .background(Theme.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.green.opacity(0.35), lineWidth: 1))

                        ShareLink(item: report.text) {
                            Label("Copy / share", systemImage: "square.and.arrow.up")
                                .font(.system(size: 15, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .foregroundStyle(Theme.textPrimary)
                                .card(raised: true)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: "Legend", color: Theme.textTertiary)
                    legend("Temp", "ProcessInfo.thermalState — Nominal, Fair, Serious, Critical")
                    legend("Perf", "P0 normally; P8 when Low Power Mode is on")
                    legend("Memory-Usage", "Mach host statistics: active + wired + compressed pages")
                    legend("GPU-Util", "Campaign completion; the daily is 0% or 100%")
                }
                .padding(14)
                .card()
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("rtx-smi")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func legend(_ key: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(key).font(Theme.mono(12, weight: .bold)).foregroundStyle(Theme.textPrimary).frame(width: 100, alignment: .leading)
            Text(text).font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
        }
    }
}
