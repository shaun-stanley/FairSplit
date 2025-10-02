import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now, summary: "FairSplit")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(SimpleEntry(date: .now, summary: readSummary()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let summary = readSummary()
        let entries = [SimpleEntry(date: .now, summary: summary)]
        completion(Timeline(entries: entries, policy: .after(.now.addingTimeInterval(60 * 30))))
    }

    private func readSummary() -> String {
        guard let defaults = UserDefaults(suiteName: "group.com.sviftstudios.FairSplit") else {
            return "Widget unavailable in this build."
        }

        let name = defaults.string(forKey: "widget.topGroup.name")
        if let totalString = defaults.string(forKey: "widget.topGroup.total"),
           let currency = defaults.string(forKey: "widget.topGroup.currency"),
           let total = Double(totalString) {
            let formatted = CurrencyFormatter.string(from: Decimal(total), currencyCode: currency)
            if let name, !name.isEmpty { return "\(name): \(formatted) total" }
            return formatted
        }

        if let name, !name.isEmpty {
            return "\(name): Open FairSplit to refresh."
        }
        return "Open FairSplit to refresh."
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
        .widgetURL(URL(string: "fairsplit://add-expense"))
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
