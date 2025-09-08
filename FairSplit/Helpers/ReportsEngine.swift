import Foundation

/// Lightweight engine to summarize report metrics off the main thread.
struct ReportsEngine {
    struct ExpenseSnap {
        let groupID: PersistentIdentifier
        let date: Date
        let category: ExpenseCategory?
        let amountInGroup: Decimal
    }

    struct Summary {
        let overallTotal: Decimal
        let perGroupTotals: [PersistentIdentifier: Decimal]
        let categoryTotals: [(ExpenseCategory, Decimal)]
        let monthlyTotals: [(StatsCalculator.YearMonth, Decimal)]
    }

    static func summarize(_ snaps: [ExpenseSnap]) -> Summary {
        var overall: Decimal = 0
        var perGroup: [PersistentIdentifier: Decimal] = [:]
        var byCategory: [ExpenseCategory: Decimal] = [:]
        var byMonth: [StatsCalculator.YearMonth: Decimal] = [:]
        let cal = Calendar.current

        for s in snaps {
            overall += s.amountInGroup
            perGroup[s.groupID, default: 0] += s.amountInGroup
            if let cat = s.category { byCategory[cat, default: 0] += s.amountInGroup }
            let comps = cal.dateComponents([.year, .month], from: s.date)
            if let y = comps.year, let m = comps.month {
                byMonth[StatsCalculator.YearMonth(year: y, month: m), default: 0] += s.amountInGroup
            }
        }

        let sortedCategories: [(ExpenseCategory, Decimal)] = byCategory.sorted { $0.value > $1.value }
        let sortedMonths: [(StatsCalculator.YearMonth, Decimal)] = byMonth.keys.sorted().map { ($0, byMonth[$0] ?? 0) }

        return Summary(
            overallTotal: overall,
            perGroupTotals: perGroup,
            categoryTotals: sortedCategories,
            monthlyTotals: sortedMonths
        )
    }
}

