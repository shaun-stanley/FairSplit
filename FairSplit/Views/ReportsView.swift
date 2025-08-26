import SwiftUI
import SwiftData

struct ReportsView: View {
    @Query(sort: [SortDescriptor(\Group.name)]) private var groups: [Group]

    private var overallTotal: Decimal {
        groups.reduce(0) { $0 + groupTotal($1) }
    }

    private func groupTotal(_ group: Group) -> Decimal {
        group.expenses.reduce(0) { partial, e in
            partial + SplitCalculator.amountInGroupCurrency(for: e, defaultCurrency: group.defaultCurrency)
        }
    }

    private var categoryTotals: [(ExpenseCategory, Decimal)] {
        var map: [ExpenseCategory: Decimal] = [:]
        for g in groups {
            for e in g.expenses {
                if let cat = e.category {
                    let amt = SplitCalculator.amountInGroupCurrency(for: e, defaultCurrency: g.defaultCurrency)
                    map[cat, default: 0] += amt
                }
            }
        }
        return ExpenseCategory.allCases.compactMap { c in
            if let v = map[c], v > 0 { return (c, v) }
            return nil
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Overview") {
                    HStack {
                        Text("Total across groups")
                        Spacer()
                        Text(CurrencyFormatter.string(from: overallTotal))
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("Groups")
                        Spacer()
                        Text("\(groups.count)")
                            .foregroundStyle(.secondary)
                    }
                }

                if !groups.isEmpty {
                    Section("Per Group Totals") {
                        ForEach(groups.sorted { $0.lastActivity > $1.lastActivity }, id: \.persistentModelID) { g in
                            HStack(alignment: .firstTextBaseline) {
                                Text(g.name)
                                Spacer(minLength: 8)
                                Text(CurrencyFormatter.string(from: groupTotal(g), currencyCode: g.defaultCurrency))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Group \(g.name), total \(CurrencyFormatter.string(from: groupTotal(g), currencyCode: g.defaultCurrency))")
                        }
                    }
                }

                if !categoryTotals.isEmpty {
                    Section("Totals by Category") {
                        ForEach(Array(categoryTotals.enumerated()), id: \.offset) { _, item in
                            let (cat, amount) = item
                            HStack(alignment: .firstTextBaseline) {
                                Text(cat.displayName)
                                Spacer(minLength: 8)
                                Text(CurrencyFormatter.string(from: amount))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(cat.displayName), total \(CurrencyFormatter.string(from: amount))")
                        }
                    }
                }
            }
            .navigationTitle("Reports")
        }
    }
}

#Preview {
    ReportsView()
        .modelContainer(for: [Group.self, Member.self, Expense.self, Settlement.self], inMemory: true)
}
