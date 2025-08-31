import SwiftUI
#if canImport(Charts)
import Charts
#endif
import SwiftData

struct ReportsView: View {
    @Query(sort: [SortDescriptor(\Group.name)]) private var groups: [Group]
    @State private var selectedGroupID: PersistentIdentifier?
    // Interactive selections for charts
    @State private var selectedMonthLabel: String?
    @State private var selectedCategoryLabel: String?
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
                scopeSection
                overviewSection
                perGroupTotalsSection
                highlightsSection
                categorySection
                memberSection
                monthlyTrendSection
            }
            .navigationTitle("Reports")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }

    // MARK: - Section Builders
    @ViewBuilder private var scopeSection: some View {
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
    }

    @ViewBuilder private var overviewSection: some View {
        Section("Overview") {
            HStack {
                Text("Total across groups")
                Spacer()
                Text(CurrencyFormatter.string(from: overallTotal, currencyCode: chartCurrencyCode))
                    .fontWeight(.semibold)
            }
            HStack {
                Text("Groups")
                Spacer()
                Text("\(scopedGroups.count)")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var perGroupTotalsSection: some View {
        let sortedGroups = scopedGroups.sorted { $0.lastActivity > $1.lastActivity }
        if !sortedGroups.isEmpty {
            Section("Per Group Totals") {
                ForEach(sortedGroups, id: \.persistentModelID) { g in
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
    }

    @ViewBuilder private var highlightsSection: some View {
        let months = monthlyTotals
        if !months.isEmpty {
            Section("Highlights") {
                let totalMonths = max(1, Set(months.map { $0.0 }).count)
                let avg = overallTotal / Decimal(totalMonths)
                HStack {
                    Text("Average per month")
                    Spacer()
                    Text(CurrencyFormatter.string(from: avg, currencyCode: chartCurrencyCode))
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
    }

    @ViewBuilder private var categorySection: some View {
        let cats = sortedCategoryTotals
        if !cats.isEmpty {
            Section("Totals by Category") {
                #if canImport(Charts)
                // Palette for consistent category colors
                let palette: [String: Color] = [
                    "Food": .green,
                    "Travel": .blue,
                    "Lodging": .purple,
                    "Other": .gray
                ]
                let rowHeight: CGFloat = 38

                Chart(cats, id: \.0) { (cat, amount) in
                    let label = cat.displayName
                    let barColor = (selectedCategoryLabel == label ? Color.accentColor : (palette[label] ?? .gray))
                    BarMark(
                        x: .value("Amount", NSDecimalNumber(decimal: amount).doubleValue),
                        y: .value("Category", label),
                        width: .automatic
                    )
                    .cornerRadius(6)
                    .foregroundStyle(barColor)
                    .opacity(selectedCategoryLabel == nil || selectedCategoryLabel == label ? 1 : 0.35)
                    .annotation(position: .trailing, alignment: .center) {
                        if selectedCategoryLabel == nil || selectedCategoryLabel == label {
                            Text(CurrencyFormatter.string(from: amount, currencyCode: chartCurrencyCode))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .chartLegend(.hidden)
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks(position: .bottom) { _ in
                        AxisGridLine().foregroundStyle(.quaternary)
                        AxisTick().foregroundStyle(.tertiary)
                        AxisValueLabel().foregroundStyle(.secondary).font(.caption2)
                    }
                }
                .chartPlotStyle { plot in
                    plot.background(.ultraThinMaterial).cornerRadius(8)
                }
                .frame(height: max(160, CGFloat(cats.count) * rowHeight + 40))
                .accessibilityLabel("Category totals chart")
                // Interactive scrubbing over Y to focus a category
                .chartOverlay { proxy in
                    GeometryReader { _ in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if let cat: String = proxy.value(atY: value.location.y) {
                                        if cat != selectedCategoryLabel { selectedCategoryLabel = cat }
                                    }
                                }
                                .onEnded { _ in selectedCategoryLabel = nil }
                            )
                    }
                }
                .sensoryFeedback(.selection, trigger: selectedCategoryLabel)
                .animation(.snappy(duration: 0.25), value: selectedCategoryLabel)
                #endif
                ForEach(Array(cats.enumerated()), id: \.offset) { _, item in
                    let (cat, amount) = item
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: cat.symbolName)
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                            Text(cat.displayName)
                        }
                        Spacer(minLength: 8)
                        Text(CurrencyFormatter.string(from: amount, currencyCode: chartCurrencyCode))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(cat.displayName), total \(CurrencyFormatter.string(from: amount, currencyCode: chartCurrencyCode))")
                }
            }
        }
    }

    @ViewBuilder private var memberSection: some View {
        if !memberTotals.isEmpty {
            Section("Totals by Member") {
                ForEach(Array(memberTotals.enumerated()), id: \.offset) { _, item in
                    let (name, amount) = item
                    HStack {
                        Text(name)
                        Spacer()
                        Text(CurrencyFormatter.string(from: amount, currencyCode: chartCurrencyCode))
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(name), total \(CurrencyFormatter.string(from: amount, currencyCode: chartCurrencyCode))")
                }
            }
        }
    }

    @ViewBuilder private var monthlyTrendSection: some View {
        let months = monthlyTotals
        if !months.isEmpty {
            Section("Monthly Trend") {
                #if canImport(Charts)
                // Precompute values and extracted styles to keep the type-checker fast
                let points: [(label: String, amount: Double)] = months.map { (ym, amount) in
                    (label: ym.label, amount: NSDecimalNumber(decimal: amount).doubleValue)
                }
                let lineColor: Color = .accentColor
                let trendFill: LinearGradient = LinearGradient(
                    gradient: Gradient(colors: [lineColor.opacity(0.28), lineColor.opacity(0.06)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                let avgDouble: Double = NSDecimalNumber(decimal: averagePerMonth).doubleValue
                let avgLabel: String = "Avg: \(CurrencyFormatter.string(from: averagePerMonth, currencyCode: chartCurrencyCode))"

                Chart {
                    // Area under the line for subtle depth
                    ForEach(points, id: \.label) { point in
                        AreaMark(
                            x: .value("Month", point.label),
                            y: .value("Amount", point.amount),
                            stacking: .standard
                        )
                        .foregroundStyle(trendFill)
                        .interpolationMethod(.catmullRom)
                    }
                    // Smoothed line on top
                    ForEach(points, id: \.label) { point in
                        LineMark(
                            x: .value("Month", point.label),
                            y: .value("Amount", point.amount)
                        )
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .foregroundStyle(lineColor)
                    }
                    // Highlight for selected month with callout
                    if let sel = selectedMonthLabel, let hit = points.first(where: { $0.label == sel }) {
                        RuleMark(x: .value("Month", hit.label))
                            .foregroundStyle(.secondary.opacity(0.5))
                        PointMark(
                            x: .value("Month", hit.label),
                            y: .value("Amount", hit.amount)
                        )
                        .symbolSize(50)
                        .foregroundStyle(lineColor)
                        .annotation(position: .top) {
                            Text(CurrencyFormatter.string(from: Decimal(hit.amount), currencyCode: chartCurrencyCode))
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                    }
                    // Average guide
                    RuleMark(y: .value("Average", avgDouble))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(Color.secondary)
                        .annotation(position: .topTrailing) {
                            Text(avgLabel)
                                .font(.caption2)
                                .foregroundStyle(Color.secondary)
                        }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(.quaternary)
                        AxisTick().foregroundStyle(.tertiary)
                        AxisValueLabel().foregroundStyle(.secondary).font(.caption2)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { _ in
                        AxisGridLine().foregroundStyle(.clear)
                        AxisTick().foregroundStyle(.tertiary)
                        AxisValueLabel().foregroundStyle(.secondary).font(.caption2)
                    }
                }
                .chartPlotStyle { plot in
                    plot.background(.ultraThinMaterial).cornerRadius(8)
                }
                .frame(height: 240)
                .accessibilityLabel("Monthly totals chart")
                // Interactive scrubbing across X to focus a month
                .chartOverlay { proxy in
                    GeometryReader { _ in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if let m: String = proxy.value(atX: value.location.x) {
                                        if m != selectedMonthLabel { selectedMonthLabel = m }
                                    }
                                }
                                .onEnded { _ in selectedMonthLabel = nil }
                            )
                    }
                }
                .sensoryFeedback(.selection, trigger: selectedMonthLabel)
                .animation(.snappy(duration: 0.25), value: selectedMonthLabel)
                #endif
            }
        }
    }
}

#Preview {
    ReportsView()
        .modelContainer(for: [Group.self, Member.self, Expense.self, Settlement.self, Comment.self], inMemory: true)
}
