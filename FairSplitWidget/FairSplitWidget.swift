import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now, summary: "FairSplit")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(SimpleEntry(date: .now, summary: "FairSplit"))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entries = [SimpleEntry(date: .now, summary: "Top group: Tap to open")]
        completion(Timeline(entries: entries, policy: .after(.now.addingTimeInterval(60 * 30))))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let summary: String
}

struct FairSplitWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("FairSplit")
                .font(.headline)
            Text(entry.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add expense")
            }
            .font(.footnote)
            .foregroundStyle(.tint)
        }
        .padding()
        .widgetURL(URL(string: "fairsplit://open"))
    }
}

@main
struct FairSplitWidgetBundle: WidgetBundle {
    var body: some Widget {
        FairSplitWidget()
    }
}

struct FairSplitWidget: Widget {
    let kind: String = "FairSplitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FairSplitWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("FairSplit")
        .description("See your group at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

