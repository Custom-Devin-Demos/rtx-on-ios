import RTXOnCore
import SwiftUI
import WidgetKit

@main
struct RTXOnWidgetBundle: WidgetBundle {
    var body: some Widget {
        SMIWidget()
    }
}

struct SMIEntry: TimelineEntry {
    let date: Date
    let report: SMIReport
}

struct SMIProvider: TimelineProvider {
    func placeholder(in context: Context) -> SMIEntry {
        SMIEntry(date: Date(), report: SMIReport.capture(progress: Progress()))
    }

    func getSnapshot(in context: Context, completion: @escaping (SMIEntry) -> Void) {
        completion(SMIEntry(date: Date(), report: SMIReport.capture(progress: SharedStore.loadProgress())))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SMIEntry>) -> Void) {
        let progress = SharedStore.loadProgress()
        let now = Date()
        let entries = (0..<4).map { i in
            let date = now.addingTimeInterval(Double(i) * 15 * 60)
            return SMIEntry(date: date, report: SMIReport.capture(progress: progress, now: date))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct SMIWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SharedStore.widgetKind, provider: SMIProvider()) { entry in
            SMIWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color.black }
        }
        .configurationDisplayName("rtx-smi")
        .description("This device in a familiar table, plus your RTX ON progress.")
        .supportedFamilies([.systemMedium, .systemLarge, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

struct SMIWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SMIEntry

    private let green = Color(red: 0x76 / 255, green: 0xB9 / 255, blue: 0x00 / 255)

    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text("rtx-smi").font(.system(size: 12, weight: .bold, design: .monospaced))
                ForEach(entry.report.lockScreenLines, id: \.self) { line in
                    Text(line).font(.system(size: 11, design: .monospaced))
                }
            }
            .minimumScaleFactor(0.7)
            .lineLimit(1)
        case .systemLarge:
            VStack(alignment: .leading, spacing: 0) {
                Text(SMIReport.timestamp.string(from: entry.date))
                    .foregroundStyle(green.opacity(0.7))
                ForEach(Array(entry.report.tableLines.enumerated()), id: \.offset) { _, line in
                    Text(line.isEmpty ? " " : line)
                }
            }
            .font(.system(size: 9.5, weight: .medium, design: .monospaced))
            .foregroundStyle(green)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        default:
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("rtx-smi").font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(.white)
                    Spacer()
                    Text(entry.date, style: .time).font(.system(size: 10, design: .monospaced)).foregroundStyle(green.opacity(0.7))
                }
                Rectangle().fill(green.opacity(0.4)).frame(height: 1)
                ForEach(entry.report.compactLines, id: \.self) { line in
                    Text(line).font(.system(size: 11, weight: .medium, design: .monospaced)).foregroundStyle(green)
                }
            }
            .minimumScaleFactor(0.7)
            .lineLimit(1)
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
