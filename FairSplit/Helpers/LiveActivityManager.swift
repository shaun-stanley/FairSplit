import Foundation

#if canImport(ActivityKit)
import ActivityKit

struct FairSplitActivityAttributes: ActivityAttributes, Identifiable {
    public struct ContentState: Codable, Hashable {
        var title: String
        var valueText: String
    }
    var id = UUID()
    var groupName: String
}

enum LiveActivityManager {
    static func start(group: Group) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attrs = FairSplitActivityAttributes(groupName: group.name)
        let valueText = summaryText(for: group)
        let state = FairSplitActivityAttributes.ContentState(title: "FairSplit", valueText: valueText)
        do {
            if #available(iOS 16.2, *) {
                _ = try Activity.request(attributes: attrs, content: .init(state: state, staleDate: nil))
            } else {
                _ = try Activity.request(attributes: attrs, contentState: state)
            }
        } catch {
            // Ignore if not permitted
        }
    }

    static func endAll() {
        Task { @MainActor in
            for activity in Activity<FairSplitActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    private static func summaryText(for group: Group) -> String {
        // Simple total of expenses in group currency
        let total: Decimal = group.expenses.reduce(0) { partial, e in
            partial + SplitCalculator.amountInGroupCurrency(for: e, defaultCurrency: group.defaultCurrency)
        }
        return "\(group.name): \(CurrencyFormatter.string(from: total, currencyCode: group.defaultCurrency))"
    }
}
#endif
