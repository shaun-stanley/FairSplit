import SwiftUI
import SwiftData

struct PersonalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: [SortDescriptor(\PersonalExpense.date, order: .reverse)]) private var expenses: [PersonalExpense]
    @Query(sort: [SortDescriptor(\PersonalBudget.categoryRaw, order: .forward)]) private var budgets: [PersonalBudget]
    @State private var showingAdd = false
    @State private var addPrefill: PersonalExpensePrefill?
    @State private var showingAccount = false
    @State private var editing: PersonalExpense?
    @State private var showingBudgets = false

    // Focus the screen on an elegant summary of "This Month".
    private var thisMonthRange: ClosedRange<Date>? { MonthScope.thisMonth.dateRange }
    private var thisMonthExpenses: [PersonalExpense] {
        guard let range = thisMonthRange else { return [] }
        return expenses.filter { range.contains($0.date) }
    }
    private var monthTotal: Decimal { thisMonthExpenses.reduce(0) { $0 + $1.amount } }
    private var quickAddOptions: [PersonalQuickAddOption] {
        var seen = Set<ExpenseCategory>()
        var options: [PersonalQuickAddOption] = []
        for expense in expenses.sorted(by: { $0.date > $1.date }) {
            guard let category = expense.category, !seen.contains(category) else { continue }
            seen.insert(category)
            options.append(PersonalQuickAddOption(category: category, lastAmount: expense.amount))
            if options.count == 4 { break }
        }
        if options.isEmpty {
            return ExpenseCategory.allCases.map { PersonalQuickAddOption(category: $0, lastAmount: nil) }
        }
        return options
    }
    private var budgetSummaries: [BudgetSummary] {
        budgets.compactMap { budget in
            guard let category = budget.category else { return nil }
            let spent = thisMonthExpenses
                .filter { $0.category == category }
                .reduce(Decimal.zero) { $0 + $1.amount }
            return BudgetSummary(
                id: budget.persistentModelID,
                category: category,
                currencyCode: budget.currencyCode,
                limit: budget.amount,
                threshold: budget.threshold,
                spent: spent
            )
        }
        .sorted { $0.category.displayName < $1.category.displayName }
    }

    var body: some View {
        NavigationStack {
            List {
                if !quickAddOptions.isEmpty {
                    Section("Quick Add") {
                        QuickAddRow(options: quickAddOptions) { option in
                            addPrefill = PersonalExpensePrefill(
                                title: option.suggestedTitle,
                                amount: option.lastAmount,
                                date: .now,
                                category: option.category,
                                note: nil
                            )
                            showingAdd = true
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                }

                Section("Budgets") {
                    if budgetSummaries.isEmpty {
                        Button {
                            showingBudgets = true
                        } label: {
                            Label("Set up budgets", systemImage: "target")
                        }
                        .buttonStyle(.borderless)
                    } else {
                        ForEach(budgetSummaries) { summary in
                            BudgetRow(summary: summary)
                                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                                .listRowBackground(Color.clear)
                        }
                        Button("Edit Budgets") { showingBudgets = true }
                            .buttonStyle(.borderless)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)

                if thisMonthExpenses.isEmpty {
                    Section {
                        emptyState
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 12, trailing: 0))
                    .listRowBackground(Color.clear)
                } else {
                    Section("Recent") {
                        ForEach(thisMonthExpenses, id: \.persistentModelID) { e in
                            PersonalExpenseCard(expense: e) { editing = e } onDelete: {
                                if reduceMotion {
                                    modelContext.delete(e)
                                    try? modelContext.save()
                                } else {
                                    withAnimation(AppAnimations.spring) {
                                        modelContext.delete(e)
                                        try? modelContext.save()
                                    }
                                }
                                Haptics.success()
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .listRowBackground(Color.clear)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .contentMargins(.top, 4, for: .scrollContent)
            .navigationTitle("Personal")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        addPrefill = nil
                        showingAdd = true
                    } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add Expense")
                    Button { showingAccount = true } label: { Image(systemName: "person.crop.circle") }
                        .accessibilityLabel("Account")
                }
            }
            // Elegant hero summary header
            .safeAreaInset(edge: .top, spacing: 0) { headerSummary }
        }
        .sheet(isPresented: $showingAccount) { AccountView() }
        .sheet(isPresented: $showingAdd, onDismiss: { addPrefill = nil }) {
            AddPersonalExpenseView(prefill: addPrefill) { title, amount, date, category, note in
                let e = PersonalExpense(title: title, amount: amount, date: date, category: category, note: note)
                if reduceMotion {
                    modelContext.insert(e)
                    try? modelContext.save()
                } else {
                    withAnimation(AppAnimations.spring) {
                        modelContext.insert(e)
                        try? modelContext.save()
                    }
                }
                Haptics.success()
                addPrefill = nil
            }
        }
        .sheet(item: $editing) { e in
            AddPersonalExpenseView(existing: e) { title, amount, date, category, note in
                if reduceMotion {
                    e.title = title
                    e.amount = amount
                    e.date = date
                    e.category = category
                    e.note = note
                    try? modelContext.save()
                } else {
                    withAnimation(AppAnimations.spring) {
                        e.title = title
                        e.amount = amount
                        e.date = date
                        e.category = category
                        e.note = note
                        try? modelContext.save()
                    }
                }
                Haptics.success()
            }
        }
        .sheet(isPresented: $showingBudgets) {
            PersonalBudgetsView()
        }
    }
}

#Preview {
    PersonalView()
        .modelContainer(for: [Group.self, Member.self, Expense.self, Settlement.self, Comment.self, PersonalExpense.self, PersonalBudget.self], inMemory: true)
}

// MARK: - Summary
private extension PersonalView {
    private var periodLabel: String { "This Month" }
    private var periodExpenses: [PersonalExpense] { thisMonthExpenses }
    private var periodTotal: Decimal { monthTotal }
    private var topCategories: [(ExpenseCategory, Decimal)] {
        var map: [ExpenseCategory: Decimal] = [:]
        for e in periodExpenses { if let c = e.category { map[c, default: 0] += e.amount } }
        return ExpenseCategory.allCases.compactMap { c in
            if let v = map[c], v > 0 { return (c, v) }
            return nil
        }.sorted { $0.1 > $1.1 }.prefix(3).map { $0 }
    }
    private var last7Values: [Double] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .day, value: -6, to: today) ?? today
        let rangeStart = thisMonthRange?.lowerBound ?? start
        let effectiveStart = max(rangeStart, start)
        var dayTotals: [Date: Decimal] = [:]
        for e in periodExpenses {
            let d = cal.startOfDay(for: e.date)
            if d >= effectiveStart && d <= today { dayTotals[d, default: 0] += e.amount }
        }
        var vals: [Double] = []
        for i in 0..<7 {
            if let d = cal.date(byAdding: .day, value: i, to: effectiveStart) {
                let v = dayTotals[cal.startOfDay(for: d)] ?? 0
                vals.append((NSDecimalNumber(decimal: v).doubleValue))
            }
        }
        return vals
    }

    // Hero header summary shown in safe area inset.
    @ViewBuilder var headerSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(periodLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(alignment: .lastTextBaseline) {
                Text(CurrencyFormatter.string(from: periodTotal, currencyCode: Locale.current.currency?.identifier ?? "INR"))
                    .font(.largeTitle).fontWeight(.bold).monospacedDigit()
                Spacer(minLength: 12)
                MiniBarChart(values: last7Values)
                    .frame(width: 140, height: 56)
                    .accessibilityHidden(true)
            }
            if !topCategories.isEmpty {
                HStack(spacing: 8) {
                    ForEach(0..<topCategories.count, id: \.self) { i in
                        let item = topCategories[i]
                        let amount = CurrencyFormatter.string(from: item.1, currencyCode: Locale.current.currency?.identifier ?? "INR")
                        Label("\(item.0.displayName) \(amount)", systemImage: item.0.symbolName)
                            .labelStyle(.titleAndIcon)
                            .font(.footnote)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule(style: .continuous).fill(.ultraThinMaterial))
                    }
                }
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [Color.accentColor.opacity(0.18), Color.accentColor.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 8)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(Color.clear.ignoresSafeArea())
    }

    @ViewBuilder var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "creditcard")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("No spending this month")
                .font(.title3).fontWeight(.semibold)
            Text("Add an expense to get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack { // keep the button compact
                Button(action: {
                    addPrefill = nil
                    showingAdd = true
                }) {
                    Label("Add Expense", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
        }
        .padding(22)
        .frame(maxWidth: 420)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// (Old summarySection removed; replaced with headerSummary)

// (Old category chip UI removed)

private struct MiniBarChart: View {
    var values: [Double]
    var body: some View {
        GeometryReader { geo in
            let maxV = max(values.max() ?? 0, 1)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(values.enumerated()), id: \.offset) { _, item in
                    let height = CGFloat(item / maxV) * geo.size.height
                    Capsule(style: .continuous)
                        .fill(Color.accentColor.opacity(0.35))
                        .frame(width: (geo.size.width - 6 * CGFloat(values.count - 1)) / CGFloat(values.count), height: height)
                }
            }
        }
    }
}
// (Old chip button removed)

// Keep a minimal MonthScope for internal range calculation
private enum MonthScope: String, CaseIterable {
    case thisMonth
    var dateRange: ClosedRange<Date>? {
        let cal = Calendar.current
        let date = Date()
        guard let start = cal.date(from: cal.dateComponents([.year, .month], from: date)),
              let endStart = cal.date(byAdding: DateComponents(month: 1, day: 0), to: start),
              let end = cal.date(byAdding: .second, value: -1, to: endStart) else { return nil }
        return start...end
    }
}

private struct PersonalExpensePrefill {
    var title: String
    var amount: Decimal?
    var date: Date
    var category: ExpenseCategory?
    var note: String?
}

private struct BudgetSummary: Identifiable {
    var id: PersistentIdentifier
    var category: ExpenseCategory
    var currencyCode: String
    var limit: Decimal
    var threshold: Decimal
    var spent: Decimal

    var progress: Double {
        guard limit > 0 else { return 0 }
        let spentValue = NSDecimalNumber(decimal: spent).doubleValue
        let limitValue = NSDecimalNumber(decimal: limit).doubleValue
        guard limitValue > 0 else { return 0 }
        let ratio = spentValue / limitValue
        return min(max(ratio, 0), 1)
    }

    var status: BudgetStatus {
        if spent >= limit { return .over }
        if spent >= threshold { return .approaching }
        return .comfort
    }

    var remainingText: String {
        switch status {
        case .over:
            let over = spent - limit
            return "Over by " + CurrencyFormatter.string(from: over, currencyCode: currencyCode)
        case .approaching:
            let remaining = max(limit - spent, 0)
            return "" + CurrencyFormatter.string(from: remaining, currencyCode: currencyCode) + " left this month"
        case .comfort:
            let remaining = max(limit - spent, 0)
            return CurrencyFormatter.string(from: remaining, currencyCode: currencyCode) + " left"
        }
    }

    enum BudgetStatus {
        case comfort
        case approaching
        case over

        var tint: Color {
            switch self {
            case .comfort: return Color.accentColor
            case .approaching: return .orange
            case .over: return .red
            }
        }
    }
}

private struct PersonalQuickAddOption: Identifiable {
    var category: ExpenseCategory
    var lastAmount: Decimal?

    var id: String { category.id }
    var suggestedTitle: String { category.displayName }
    var iconName: String { category.symbolName }
    var formattedAmount: String? {
        guard let amount = lastAmount else { return nil }
        return CurrencyFormatter.string(from: amount, currencyCode: Locale.current.currency?.identifier ?? "INR")
    }
}

private struct QuickAddRow: View {
    var options: [PersonalQuickAddOption]
    var onSelect: (PersonalQuickAddOption) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(options) { option in
                    Button {
                        onSelect(option)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Label(option.suggestedTitle, systemImage: option.iconName)
                                .labelStyle(.titleAndIcon)
                                .font(.callout)
                            if let amount = option.formattedAmount {
                                Text(amount)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Tap to log quickly")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 160, alignment: .leading)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

private struct BudgetRow: View {
    var summary: BudgetSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Label(summary.category.displayName, systemImage: summary.category.symbolName)
                    .labelStyle(.titleAndIcon)
                    .font(.headline)
                Spacer()
                Text(leadingText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: summary.progress)
                .tint(summary.status.tint)
            Text(summary.remainingText)
                .font(.footnote)
                .foregroundStyle(summary.status == .comfort ? .secondary : summary.status.tint)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel))
    }

    private var leadingText: String {
        let spent = CurrencyFormatter.string(from: summary.spent, currencyCode: summary.currencyCode)
        let total = CurrencyFormatter.string(from: summary.limit, currencyCode: summary.currencyCode)
        return "\(spent) of \(total)"
    }

    private var accessibilityLabel: String {
        switch summary.status {
        case .over:
            return "\(summary.category.displayName) budget exceeded. Spent \(leadingText). \(summary.remainingText)."
        case .approaching:
            return "\(summary.category.displayName) budget near limit. \(leadingText). \(summary.remainingText)."
        case .comfort:
            return "\(summary.category.displayName) budget. \(leadingText). \(summary.remainingText)."
        }
    }
}

private struct PersonalBudgetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\PersonalBudget.categoryRaw, order: .forward)]) private var budgets: [PersonalBudget]
    @State private var amountTexts: [ExpenseCategory: String] = [:]
    @State private var errorMessage: String?

    private let currencyCode = Locale.current.currency?.identifier ?? "INR"

    var body: some View {
        NavigationStack {
            Form {
                Section("Monthly caps") {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label(category.displayName, systemImage: category.symbolName)
                                Spacer()
                                TextField("Amount", text: binding(for: category))
                                    .multilineTextAlignment(.trailing)
                                    .keyboardType(.decimalPad)
                                    .textContentType(.oneTimeCode)
                            }
                            if let existing = existingBudget(for: category) {
                                Text("Current: " + CurrencyFormatter.string(from: existing.amount, currencyCode: existing.currencyCode))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Optional. Leave blank to skip this category.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    Button("Save") { save() }
                        .buttonStyle(.borderedProminent)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Personal Budgets")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .onAppear(perform: load)
        }
    }

    private func binding(for category: ExpenseCategory) -> Binding<String> {
        Binding<String>(
            get: { amountTexts[category] ?? existingText(for: category) ?? "" },
            set: { amountTexts[category] = $0 }
        )
    }

    private func existingBudget(for category: ExpenseCategory) -> PersonalBudget? {
        budgets.first { $0.category == category }
    }

    private func existingText(for category: ExpenseCategory) -> String? {
        guard let budget = existingBudget(for: category) else { return nil }
        return numberFormatter.string(from: NSDecimalNumber(decimal: budget.amount))
    }

    private func load() {
        if !amountTexts.isEmpty { return }
        for category in ExpenseCategory.allCases {
            if let text = existingText(for: category) {
                amountTexts[category] = text
            }
        }
    }

    private func save() {
        errorMessage = nil

        var parsedValues: [ExpenseCategory: Decimal] = [:]
        var clearedCategories: Set<ExpenseCategory> = []

        for category in ExpenseCategory.allCases {
            let raw = amountTexts[category]?.trimmingCharacters(in: .whitespacesAndNewlines)

            guard let raw, !raw.isEmpty else {
                clearedCategories.insert(category)
                continue
            }

            guard let decimal = parseDecimal(raw), decimal > 0 else {
                errorMessage = "Enter valid numbers using digits and a decimal separator."
                return
            }

            parsedValues[category] = decimal
        }

        for category in ExpenseCategory.allCases {
            let existing = existingBudget(for: category)
            if let value = parsedValues[category] {
                if let existing {
                    existing.amount = value
                    existing.currencyCode = currencyCode
                    existing.threshold = (value * Decimal(85)) / Decimal(100)
                } else {
                    let budget = PersonalBudget(category: category, amount: value, currencyCode: currencyCode)
                    modelContext.insert(budget)
                }
            } else if clearedCategories.contains(category), let existing {
                modelContext.delete(existing)
            }
        }

        do {
            try modelContext.save()
            Haptics.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func parseDecimal(_ text: String) -> Decimal? {
        if let number = numberFormatter.number(from: text) {
            return number.decimalValue
        }
        let normalised = text.replacingOccurrences(of: Locale.current.decimalSeparator ?? ".", with: ".")
        return Decimal(string: normalised)
    }

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.locale = Locale.current
        return formatter
    }
}

private struct PersonalExpenseCard: View {
    var expense: PersonalExpense
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        let amountString = CurrencyFormatter.string(from: expense.amount, currencyCode: expense.currencyCode)
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: expense.category?.symbolName ?? "creditcard")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(.headline)
                HStack(spacing: 6) {
                    if let cat = expense.category {
                        Text(cat.displayName)
                            .foregroundStyle(.secondary)
                    }
                    Text("\(expense.date, style: .date)")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
            Spacer(minLength: 12)
            Text(amountString)
                .fontWeight(.semibold)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .swipeActions {
            Button("Edit") { onEdit() }.tint(.blue)
            Button("Delete", role: .destructive) { onDelete() }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onEdit() }
        .accessibilityAction(named: Text("Delete")) { onDelete() }
        .accessibilityLabel(Text("\(expense.title), \(amountString) on \(expense.date.formatted(date: .abbreviated, time: .omitted))."))
        .accessibilityHint(Text("Double-tap to edit. Use Actions to delete."))
    }
}

private struct AddPersonalExpenseView: View {
    var existing: PersonalExpense?
    var prefill: PersonalExpensePrefill?
    var onSave: (_ title: String, _ amount: Decimal, _ date: Date, _ category: ExpenseCategory?, _ note: String?) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var amount: Double?
    @State private var date: Date
    @State private var category: ExpenseCategory?
    @State private var note: String

    init(existing: PersonalExpense? = nil, prefill: PersonalExpensePrefill? = nil, onSave: @escaping (_ title: String, _ amount: Decimal, _ date: Date, _ category: ExpenseCategory?, _ note: String?) -> Void) {
        self.existing = existing
        self.prefill = prefill
        self.onSave = onSave
        _title = State(initialValue: existing?.title ?? prefill?.title ?? "")
        _amount = State(initialValue: existing.map { Double(truncating: NSDecimalNumber(decimal: $0.amount)) } ?? prefill?.amount.map { Double(truncating: NSDecimalNumber(decimal: $0)) })
        _date = State(initialValue: existing?.date ?? prefill?.date ?? .now)
        _category = State(initialValue: existing?.category ?? prefill?.category)
        _note = State(initialValue: existing?.note ?? prefill?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Amount", value: $amount, format: .currency(code: Locale.current.currency?.identifier ?? "INR"))
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                Section("Category") {
                    Picker("Category", selection: Binding(get: {
                        category
                    }, set: { category = $0 })) {
                        Text("None").tag(nil as ExpenseCategory?)
                        ForEach(ExpenseCategory.allCases, id: \.self) { c in
                            Text(c.displayName).tag(c as ExpenseCategory?)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                Section("Notes") {
                    TextField("Note", text: $note)
                }
            }
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .navigationTitle(existing == nil ? "New Personal Expense" : "Edit Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).disabled(!canSave) }
            }
        }
    }

    private var canSave: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard let amount, amount > 0 else { return false }
        return true
    }

    private func save() {
        guard let amount else { return }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(title, Decimal(amount), date, category, trimmed.isEmpty ? nil : trimmed)
        dismiss()
    }
}
