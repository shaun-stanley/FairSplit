import Foundation
import SwiftData

enum StatsCalculator {
    /// Returns the total owed (share of expenses) per member in the group's currency.
    static func totalsByMember(for group: Group) -> [PersistentIdentifier: Decimal] {
        var totals: [PersistentIdentifier: Decimal] = Dictionary(uniqueKeysWithValues: group.members.map { ($0.persistentModelID, 0) })
        for e in group.expenses {
            let amount = SplitCalculator.amountInGroupCurrency(for: e, defaultCurrency: group.defaultCurrency)
            let split: [PersistentIdentifier: Decimal]
            if e.shares.isEmpty {
                split = SplitCalculator.evenSplit(amount: amount, among: e.participants)
            } else {
                split = SplitCalculator.weightedSplit(amount: amount, shares: e.shares)
            }
            for (id, share) in split { totals[id, default: 0] += share }
        }
        return totals
    }

    /// Returns the total expense amount per category in the group's currency.
    static func totalsByCategory(for group: Group) -> [ExpenseCategory: Decimal] {
        var totals: [ExpenseCategory: Decimal] = [:]
        for e in group.expenses {
            guard let cat = e.category else { continue }
            let amount = SplitCalculator.amountInGroupCurrency(for: e, defaultCurrency: group.defaultCurrency)
            totals[cat, default: 0] += amount
        }
        return totals
    }
}

