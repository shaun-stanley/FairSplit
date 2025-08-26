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

    struct YearMonth: Hashable, Comparable {
        let year: Int
        let month: Int
        static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
            if lhs.year == rhs.year { return lhs.month < rhs.month }
            return lhs.year < rhs.year
        }
        var label: String {
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            let cal = Calendar.current
            if let date = cal.date(from: comps) {
                return date.formatted(.dateTime.month(.abbreviated).year())
            }
            return "\(year)-\(month)"
        }
    }

    /// Returns totals per month (across all provided groups) in each group's currency converted per expense.
    static func totalsByMonth(groups: [Group]) -> [YearMonth: Decimal] {
        var totals: [YearMonth: Decimal] = [:]
        let cal = Calendar.current
        for g in groups {
            for e in g.expenses {
                let comps = cal.dateComponents([.year, .month], from: e.date)
                guard let y = comps.year, let m = comps.month else { continue }
                let key = YearMonth(year: y, month: m)
                let amount = SplitCalculator.amountInGroupCurrency(for: e, defaultCurrency: g.defaultCurrency)
                totals[key, default: 0] += amount
            }
        }
        return totals
    }
}
