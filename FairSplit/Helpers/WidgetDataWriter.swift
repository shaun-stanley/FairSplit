import Foundation
import SwiftData

enum WidgetDataWriter {
    static let appGroupID = "group.com.sviftstudios.FairSplit"
    static let availabilityKey = "widget.appGroup.available"

    static func updateTopGroupSummary(groups: [Group]) {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else {
            updateAvailabilityFlag(false)
            return
        }

        updateAvailabilityFlag(true)

        guard let group = groups.filter({ !$0.isArchived }).sorted(by: { $0.lastActivity > $1.lastActivity }).first ?? groups.first else { return }

        let total: Decimal = group.expenses.reduce(0) { partial, expense in
            partial + SplitCalculator.amountInGroupCurrency(for: expense, defaultCurrency: group.defaultCurrency)
        }
        sharedDefaults.set(group.name, forKey: "widget.topGroup.name")
        sharedDefaults.set("\(NSDecimalNumber(decimal: total).doubleValue)", forKey: "widget.topGroup.total")
        sharedDefaults.set(group.defaultCurrency, forKey: "widget.topGroup.currency")
    }

    private static func updateAvailabilityFlag(_ isAvailable: Bool) {
        let defaults = UserDefaults.standard
        let existingObject = defaults.object(forKey: availabilityKey)

        if existingObject == nil {
            defaults.set(isAvailable, forKey: availabilityKey)
            if !isAvailable {
                Diagnostics.event("Widget app group unavailable; widget updates disabled")
            }
            return
        }

        guard let previous = existingObject as? Bool, previous != isAvailable else { return }
        defaults.set(isAvailable, forKey: availabilityKey)
        let message = isAvailable ? "Widget app group available; widget updates enabled" : "Widget app group unavailable; widget updates disabled"
        Diagnostics.event(message)
    }
}
