import Foundation
import SwiftData

enum WidgetDataWriter {
    static let appGroupID = "group.com.sviftstudios.FairSplit"

    static func updateTopGroupSummary(groups: [Group]) {
        let defaults: UserDefaults
        if let suite = UserDefaults(suiteName: appGroupID) {
            defaults = suite
        } else {
            defaults = .standard
            Diagnostics.event("Widget app group unavailable; storing summary locally only")
        }

        guard let group = groups.filter({ !$0.isArchived }).sorted(by: { $0.lastActivity > $1.lastActivity }).first ?? groups.first else { return }

        let total: Decimal = group.expenses.reduce(0) { partial, e in
            partial + SplitCalculator.amountInGroupCurrency(for: e, defaultCurrency: group.defaultCurrency)
        }
        defaults.set(group.name, forKey: "widget.topGroup.name")
        defaults.set("\(NSDecimalNumber(decimal: total).doubleValue)", forKey: "widget.topGroup.total")
        defaults.set(group.defaultCurrency, forKey: "widget.topGroup.currency")
        defaults.synchronize()
    }
}
