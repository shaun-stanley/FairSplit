import SwiftUI
#if canImport(Charts)
import Charts
#endif
import SwiftData

struct ReportsView: View {
    @Query(sort: [SortDescriptor(\Group.name)]) private var groups: [Group]
    @State private var selectedGroupID: PersistentIdentifier?
    @AppStorage(AppSettings.defaultCurrencyKey) private var defaultCurrency: String = AppSettings.defaultCurrencyCode()
    private var groupSelection: Binding<PersistentIdentifier?> {
        Binding<PersistentIdentifier?>(
            get: { selectedGroupID },
            set: { selectedGroupID = $0 }
        )
    }

    private var scopedGroups: [Group] {
        if let id = selectedGroupID, let g = groups.first(where: { $0.persistentModelID == id }) { return [g] }
        return groups
    }

    private var overallTotal: Decimal {
        scopedGroups.reduce(0) { $0 + groupTotal($1) }
    }

    private func groupTotal(_ group: Group) -> Decimal {
        group.expenses.reduce(0) { partial, e in
            partial + SplitCalculator.amountInGroupCurrency(for: e, defaultCurrency: group.defaultCurrency)
        }
    }

    private var categoryTotals: [(ExpenseCategory, Decimal)] {
        var map: [ExpenseCategory: Decimal] = [:]
        for g in scopedGroups {
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

    private var memberTotals: [(String, Decimal)] {
        var map: [String: Decimal] = [:]
        for g in scopedGroups {
            let perMember = StatsCalculator.totalsByMember(for: g)
            for m in g.members {
                let name = m.name
                map[name, default: 0] += perMember[m.persistentModelID] ?? 0
            }
        }
        return map.sorted { $0.value > $1.value }
    }

    private var monthlyTotals: [(StatsCalculator.YearMonth, Decimal)] {
        let totals = StatsCalculator.totalsByMonth(groups: scopedGroups)
        return totals.keys.sorted().map { ($0, totals[$0] ?? 0) }
    }
    private var sortedCategoryTotals: [(ExpenseCategory, Decimal)] {
        categoryTotals.sorted { $0.1 > $1.1 }
    }
    private var chartCurrencyCode: String { scopedGroups.first?.defaultCurrency ?? defaultCurrency }
    private var averagePerMonth: Decimal {
        let months = max(1, Set(monthlyTotals.map { $0.0 }).count)
        return overallTotal / Decimal(months)
    }

    var body: some View {
        NavigationStack {
            List {
                if !groups.isEmpty {
                    Section("Scope") {
                        Picker("Group", selection: groupSelection) {
                            Text("All Groups").tag(nil as PersistentIdentifier?)
                            ForEach(groups, id: \.persistentModelID) { g in
                                Text(g.name).tag(g.persistentModelID as PersistentIdentifier?)
                            }
                        }
                        .pickerStyle(.navigationLink)
                        #if canImport(TipKit)
                        .popoverTip(AppTips.filters)
                        #endif
                    }
                }
                Section("Overview") {
                    HStack {
                        Text("Total across groups")
                        Spacer()
                        Text(CurrencyFormatter.string(from: overallTotal, currencyCode: scopedGroups.first?.defaultCurrency ?? defaultCurrency))
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("Groups")
                        Spacer()
                        Text("\(scopedGroups.count)")
                            .foregroundStyle(.secondary)
                    }
                }

                if !scopedGroups.isEmpty {
                    Section("Per Group Totals") {
                        ForEach(scopedGroups.sorted { $0.lastActivity > $1.lastActivity }, id: \.persistentModelID) { g in
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

                // Simple KPI section
                if !monthlyTotals.isEmpty {
                    Section("Highlights") {
                        let totalMonths = max(1, Set(monthlyTotals.map { $0.0 }).count)
                        let avg = overallTotal / Decimal(totalMonths)
                        HStack {
                            Text("Average per month")
                            Spacer()
                            Text(CurrencyFormatter.string(from: avg, currencyCode: scopedGroups.first?.defaultCurrency ?? defaultCurrency))
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Months covered")
                            Spacer()
                            Text("\(totalMonths)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if !categoryTotals.isEmpty {
                    Section("Totals by Category") {
                        // Chart (when available)
                        #if canImport(Charts)
                        Chart(sortedCategoryTotals, id: \.0) { (cat, amount) in
                            BarMark(
                                x: .value("Amount", NSDecimalNumber(decimal: amount).doubleValue),
                                y: .value("Category", cat.displayName),
                                width: .automatic
                            )
                            .annotation(position: .trailing, alignment: .center) {
                                Text(CurrencyFormatter.string(from: amount, currencyCode: chartCurrencyCode))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .foregroundStyle(by: .value("Category", cat.displayName))
                        }
                        .chartForegroundStyleScale([
                            "Food": .green,
                            "Travel": .blue,
                            "Lodging": .purple,
                            "Other": .gray
                        ])
                        .chartLegend(.hidden)
                        .chartYAxis(.hidden)
                        .chartPlotStyle { plot in
                            plot.background(.ultraThinMaterial).cornerRadius(8)
                        }
                        .frame(height: max(160, CGFloat(sortedCategoryTotals.count) * 32 + 40))
                        .accessibilityLabel("Category totals chart")
                        #endif
                        // List (readable values)
                        ForEach(Array(sortedCategoryTotals.enumerated()), id: \.offset) { _, item in
                            let (cat, amount) = item
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: cat.symbolName)
                                        .foregroundStyle(.secondary)
                                        .accessibilityHidden(true)
                                    Text(cat.displayName)
                                }
                                Spacer(minLength: 8)
                                Text(CurrencyFormatter.string(from: amount, currencyCode: scopedGroups.first?.defaultCurrency ?? defaultCurrency))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(cat.displayName), total \(CurrencyFormatter.string(from: amount, currencyCode: scopedGroups.first?.defaultCurrency ?? defaultCurrency))")
                        }
                    }
                }

                if !memberTotals.isEmpty {
                    Section("Totals by Member") {
                        ForEach(Array(memberTotals.enumerated()), id: \.offset) { _, item in
                            let (name, amount) = item
                            HStack {
                                Text(name)
                                Spacer()
                                Text(CurrencyFormatter.string(from: amount, currencyCode: scopedGroups.first?.defaultCurrency ?? defaultCurrency))
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(name), total \(CurrencyFormatter.string(from: amount, currencyCode: scopedGroups.first?.defaultCurrency ?? defaultCurrency))")
                        }
                    }
                }

                if !monthlyTotals.isEmpty {
                    Section("Monthly Trend") {
                        #if canImport(Charts)
                        Chart {
                            ForEach(monthlyTotals, id: \.0) { (ym, amount) in
                                AreaMark(
                                    x: .value("Month", ym.label),
                                    yStart: .value("Min", 0),
                                    y: .value("Amount", NSDecimalNumber(decimal: amount).doubleValue)
                                )
                                .foregroundStyle(LinearGradient(colors: [.accentColor.opacity(0.25), .accentColor.opacity(0.05)], startPoint: .top, endPoint: .bottom))

                                LineMark(
                                    x: .value("Month", ym.label),
                                    y: .value("Amount", NSDecimalNumber(decimal: amount).doubleValue)
                                )
                                .interpolationMethod(.catmullRom)
                                .lineStyle(.init(lineWidth: 2))
                                .foregroundStyle(.accent)

                                PointMark(
                                    x: .value("Month", ym.label),
                                    y: .value("Amount", NSDecimalNumber(decimal: amount).doubleValue)
                                )
                                .foregroundStyle(.accent)
                            }
                            // Average rule
                            RuleMark(y: .value("Average", NSDecimalNumber(decimal: averagePerMonth).doubleValue))
                                .lineStyle(.init(lineWidth: 1, dash: [4, 4]))
                                .foregroundStyle(.secondary)
                                .annotation(position: .topTrailing) {
                                    Text("Avg: \(CurrencyFormatter.string(from: averagePerMonth, currencyCode: chartCurrencyCode))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                        }
                        .chartYAxis { AxisMarks(position: .leading) }
                        .chartPlotStyle { plot in
                            plot.background(.ultraThinMaterial).cornerRadius(8)
                        }
                        .frame(height: 240)
                        .accessibilityLabel("Monthly totals chart")
                        #endif
                    }
                }
            }
            .navigationTitle("Reports")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }
}

#Preview {
    ReportsView()
        .modelContainer(for: [Group.self, Member.self, Expense.self, Settlement.self, Comment.self], inMemory: true)
}
